#!/bin/sh
set -u

mkdir -p /workspace

configure_opencode() {
  opencode_config_dir="${XDG_CONFIG_HOME:-/workspace/.config}/opencode"
  mkdir -p "$opencode_config_dir"
  cat > "opencode.json" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "update": "notify",
  "share": "manual",
  "model": "opencode/muse-spark-1.3-contributor-free",
  "provider": {
    "opencode": {
      "models": {
        "muse-spark-1.3-contributor-free": {
          "options": {
            "reasoningEffort": "xhigh"
          }
        }
      }
    }
  },
  "permission": {
    "read": "allow",
    "edit": "allow",
    "glob": "allow",
    "grep": "allow",
    "list": "allow",
    "bash": {
      "*": "allow",
      "kubectl *": "deny"
    },
    "external_directory": "allow",
    "webfetch": "allow",
    "websearch": "allow"
  },
  "instructions": ["/workspace/prodhub-instructions.md"]
}
EOF
}

write_workspace_instructions() {
  cat > /workspace/prodhub-instructions.md <<EOF
# ProdHub preview requirements

When starting an application in this workspace, listen on \`0.0.0.0\` and use port \`${PORT}\` exactly. Do not select a fallback port. The public preview URL is: ${PRODHUB_PREVIEW_URL:-not assigned}. Keep the application running while the preview is needed.
EOF
}

configure_opencode
write_workspace_instructions

# OpenCode's Google provider uses GOOGLE_GENERATIVE_AI_API_KEY. Keep the
# Gemini-compatible name as well for tools that still expect GEMINI_API_KEY.
add_google_api_key_alias() {
  if [ -s /workspace/.ai-env ] && grep -q '^GEMINI_API_KEY=' /workspace/.ai-env; then
    sed 's/^GEMINI_API_KEY=/GOOGLE_GENERATIVE_AI_API_KEY=/' /workspace/.ai-env >> /workspace/.ai-env
  fi
}

if ! python -c 'import json, os, urllib.request; h={"X-Service-Name":"cloudedge-deployer","uuid":os.environ["AI_USER_ID"]}; t=os.environ.get("AI_PRODHUB_TOKEN"); h["Authorization"]="Bearer "+t if t else None; h={k:v for k,v in h.items() if v}; u=os.environ["AI_PRODHUB_URL"].rstrip("/")+"/credentialProvider/ai-workspace"; d=json.load(urllib.request.urlopen(urllib.request.Request(u, headers=h), timeout=10)); names={"OpenAI":"OPENAI_API_KEY","Gemini":"GEMINI_API_KEY","Anthropic":"ANTHROPIC_API_KEY","DeepSeek":"DEEPSEEK_API_KEY","OpenRouter":"OPENROUTER_API_KEY","Meta":"META_API_KEY"}; print("AI credentials received: "+str([{"type":x.get("type"),"keys":sorted(json.loads(x["credentialMetadata"]).keys())} for x in d.get("response",[]) if x.get("credentialMetadata")]), flush=True); out=[]; [out.append(names[x.get("type")]+"="+json.loads(x["credentialMetadata"])["api_key"]) for x in d.get("response",[]) if x.get("credentialMetadata") and x.get("type") in names and json.loads(x["credentialMetadata"]).get("api_key")]; print("AI environment variables: "+str([{"name":v.split("=",1)[0],"configured":bool(v.split("=",1)[1]),"length":len(v.split("=",1)[1])} for v in out]), flush=True); open("/workspace/.ai-env","w").write("\n".join(out)+"\n")'; then
  echo "AI credentials could not be loaded; continuing with the workspace available for debugging." >&2
fi
add_google_api_key_alias

configure_opencode_command() {
  opencode_wrapper_dir="/workspace/.opencode/bin"
  opencode_search_path="${PATH#"$opencode_wrapper_dir:"}"
  opencode_bin="$(PATH="$opencode_search_path" command -v opencode 2>/dev/null || true)"
  if [ -z "$opencode_bin" ]; then
    return
  fi

  mkdir -p "$opencode_wrapper_dir"
  cat > "$opencode_wrapper_dir/opencode" <<EOF
#!/bin/sh
# kubectl exec starts a fresh shell, so load the workspace credentials for OpenCode itself.
if [ -f /workspace/repository/.env ]; then
  set -a
  . /workspace/repository/.env
  set +a
fi
exec "$opencode_bin" "\$@"
EOF
  chmod 0755 "$opencode_wrapper_dir/opencode"
}

set_workspace_ownership() {
  if [ "$(id -u)" -eq 0 ]; then
    chown -R 1001:1001 /workspace/repository
  fi
}

if [ "${AI_WORKSPACE_STANDALONE:-false}" = "true" ] || [ -z "${AI_REPOSITORY:-}" ]; then
  mkdir -p /workspace/repository
  if [ -f /workspace/.ai-env ]; then
    cp /workspace/.ai-env /workspace/repository/.env
    chmod 0600 /workspace/repository/.env
  fi
  set_workspace_ownership
  rm -f /workspace/.ai-env
  configure_opencode_command
  echo "Standalone AI workspace ready at /workspace/repository"
  echo "Preview URL: ${PRODHUB_PREVIEW_URL:-not assigned}; application port: ${PORT:-not assigned}"
  exec sleep infinity
fi

if ! python -c 'import json, os, urllib.request; h={"X-Service-Name":"cloudedge-deployer","uuid":os.environ["AI_USER_ID"]}; t=os.environ.get("AI_PRODHUB_TOKEN"); h["Authorization"]="Bearer "+t if t else None; h={k:v for k,v in h.items() if v}; u=os.environ["AI_PRODHUB_URL"].rstrip("/")+"/credentialProvider/scm-workspace/"+os.environ["AI_SCM_ID"]; d=json.load(urllib.request.urlopen(urllib.request.Request(u, headers=h), timeout=10)); metadata=json.loads(d["response"]["credentialMetadata"]); token=metadata.get("github_token") or metadata.get("gitlab_token") or metadata.get("bitbucket_app_password"); print("SCM credentials received: keys="+str(sorted(metadata.keys())), flush=True); print("SCM token: "+("****" if token else "<missing>")+" (length="+str(len(token or ""))+")", flush=True); open("/workspace/.scm-credential.json","w").write(d["response"]["credentialMetadata"])'; then
  echo "SCM credentials could not be loaded; continuing with the workspace available for debugging." >&2
fi
if ! python -c 'import json, os; d=json.load(open("/workspace/.scm-credential.json")); token=d.get("github_token") or d.get("gitlab_token") or d.get("bitbucket_app_password"); repo=os.environ["AI_REPOSITORY"].strip("/"); is_gitlab=bool(d.get("gitlab_token")); is_bitbucket=bool(d.get("bitbucket_app_password")); prefix=d.get("gitlab_group") if is_gitlab else (d.get("bitbucket_workspace") if is_bitbucket else (d.get("github_org") or d.get("github_owner"))); repo=repo if "/" in repo or not prefix else prefix.strip("/")+"/"+repo; base=d.get("gitlab_url","https://github.com").rstrip("/") if is_gitlab else ("https://bitbucket.org" if is_bitbucket else "https://github.com"); open("/workspace/.git-token","w").write(d.get("bitbucket_username","git")+"\n"+str(token or "")+"\n"); open("/workspace/.git-url","w").write(base+"/"+repo+".git") if token else (_ for _ in ()).throw(RuntimeError("SCM token was not found"))'; then
  echo "SCM clone configuration could not be prepared; continuing with the workspace available for debugging." >&2
fi

printf '#!/bin/sh\ncase "$1" in *Username*) sed -n "1p" /workspace/.git-token ;; *) sed -n "2p" /workspace/.git-token ;; esac\n' > /workspace/.git-askpass
chmod 0700 /workspace/.git-askpass
export GIT_ASKPASS=/workspace/.git-askpass GIT_TERMINAL_PROMPT=0
rm -rf /workspace/repository
# Agents operate on the current branch tip; fetching all history only increases
# startup time and EmptyDir usage. A full clone can still be explicitly requested.
git_clone_args="--single-branch --branch $AI_REPO_BRANCH"
if [ "${AI_WORKSPACE_FULL_GIT_HISTORY:-false}" != "true" ]; then
  git_clone_args="--depth 1 $git_clone_args"
fi
if ! git clone $git_clone_args "$(cat /workspace/.git-url)" /workspace/repository; then
  echo "Repository clone failed; keeping the container alive for debugging." >&2
  exec sleep infinity
fi
cp /workspace/.ai-env /workspace/repository/.env
chmod 0600 /workspace/repository/.env
set_workspace_ownership
rm -f /workspace/.ai-env /workspace/.scm-credential.json /workspace/.git-token /workspace/.git-askpass /workspace/.git-url
configure_opencode_command
echo "Repository ready at /workspace/repository"
if command -v opencode >/dev/null 2>&1; then
  echo "OpenCode CLI ready: $(opencode --version 2>/dev/null || echo version-unavailable)"
  echo "Connect to the pod terminal, then run: opencode"
else
  echo "OpenCode CLI is not installed in this workspace image." >&2
fi
exec sleep infinity
