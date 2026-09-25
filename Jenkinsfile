pipeline {
    agent any
    options {
        timestamps()
        disableConcurrentBuilds()
    }
    parameters {
        string(name: 'REPO_URL', defaultValue: 'git@github.com:SwaDeshiTech/prodhub-ai-workspace.git', description: 'Repository containing the AI workspace build definitions')
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Branch to build when COMMIT_ID is empty')
        string(name: 'COMMIT_ID', defaultValue: '', description: 'Optional commit, tag, or ref to build')
        string(name: 'GIT_CREDENTIAL', defaultValue: '', description: 'Jenkins SSH credential used for checkout')
        string(name: 'DOCKER_CREDENTIAL_ID', defaultValue: '', description: 'Jenkins Docker Hub username/password credential')
        string(name: 'DOCKER_IMAGE_HASH_VALUE', defaultValue: 'harry2654/prodhub:unused', description: 'Repository and tag seed; the pipeline replaces the tag per image')
    }
    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                script {
                    def requestedRef = params.COMMIT_ID?.trim() ?: params.BRANCH_NAME?.trim() ?: 'main'
                    def checkoutBranch = requestedRef.startsWith('refs/') ? requestedRef : "*/${requestedRef}"
                    checkout([$class: 'GitSCM',
                        branches: [[name: checkoutBranch]],
                        userRemoteConfigs: [[
                            credentialsId: params.GIT_CREDENTIAL?.trim(),
                            url: params.REPO_URL.trim()
                        ]],
                        extensions: [[$class: 'CloneOption', depth: 1, noTags: false, shallow: true]]
                    ])
                }
            }
        }
        stage('Build, test, and publish images') {
            steps {
                script {
                    def imageSeed = params.DOCKER_IMAGE_HASH_VALUE?.trim()
                    if (!imageSeed || !(imageSeed ==~ /[A-Za-z0-9._\/:@-]+/)) {
                        error('DOCKER_IMAGE_HASH_VALUE must contain only Docker image characters')
                    }
                    def seedWithoutDigest = imageSeed.split('@', 2)[0]
                    def lastSlash = seedWithoutDigest.lastIndexOf('/')
                    def lastColon = seedWithoutDigest.lastIndexOf(':')
                    def imageRepository = (lastColon > lastSlash) ? seedWithoutDigest[0..<lastColon] : seedWithoutDigest
                    def successful = []
                    def failed = []
                    def reclaimDockerSpace = { imageTag ->
                        withEnv(["IMAGE_TAG=${imageTag}"]) {
                            sh '''
                                set +e
                                docker image rm -f "$IMAGE_TAG" >/dev/null 2>&1 || true
                                docker container prune -f >/dev/null 2>&1 || true
                                docker image prune -af >/dev/null 2>&1 || true
                                docker builder prune -af >/dev/null 2>&1 || true
                                docker system df || true
                            '''
                        }
                    }
                    sh '''
                        set -eu
                        mkdir -p artifacts
                        : > artifacts/ai-workspace-images.env
                        docker container prune -f >/dev/null 2>&1 || true
                        docker image prune -af >/dev/null 2>&1 || true
                        docker builder prune -af >/dev/null 2>&1 || true
                    '''
                    withEnv(["DOCKER_CONFIG=${env.WORKSPACE}/.docker"]) {
                        withCredentials([usernamePassword(credentialsId: params.DOCKER_CREDENTIAL_ID.trim(), usernameVariable: 'REGISTRY_USERNAME', passwordVariable: 'REGISTRY_PASSWORD')]) {
                            sh '''
                                set -eu
                                mkdir -p "$DOCKER_CONFIG"
                                printf '%s' "$REGISTRY_PASSWORD" | docker login --username "$REGISTRY_USERNAME" --password-stdin
                            '''
                        }
                        try {
                                def variants = sh(
                                    script: '''
                                        set -eu
                                        {
                                            printf '%s\\n' ai-workspace
                                            find ai-workspace -mindepth 2 -maxdepth 2 -type f -name build.sh -print |
                                                sed 's#/build.sh$##' | LC_ALL=C sort
                                        } | while IFS= read -r variant; do
                                            test -f "$variant/Dockerfile"
                                            test -f "$variant/build.sh"
                                            printf '%s\\n' "$variant"
                                        done
                                    ''',
                                    returnStdout: true
                                ).trim().split('\\n')
                                variants.each { variantPath ->
                                    if (!variantPath?.trim()) { return }
                                    def variantName = variantPath == 'ai-workspace' ? 'opencode' : variantPath.substring('ai-workspace/'.length())
                                    def imageTag = "${imageRepository}:ai-workspace-${variantName}"
                                    try {
                                        withEnv(["IMAGE_TAG=${imageTag}", "PUSH_IMAGE=false", "AI_WORKSPACE_BUILD_SCRIPT=${variantPath}/build.sh"]) {
                                            sh '''
                                                set -eu
                                                docker image rm -f "$IMAGE_TAG" || true
                                                chmod +x "$AI_WORKSPACE_BUILD_SCRIPT"
                                                bash "$AI_WORKSPACE_BUILD_SCRIPT"
                                                docker image inspect "$IMAGE_TAG" >/dev/null
                                                docker run --rm --entrypoint sh "$IMAGE_TAG" -c '
                                                    set -eu
                                                    command -v opencode >/dev/null
                                                    test -x /usr/local/bin/ai-workspace-entrypoint
                                                '
                                                docker push "$IMAGE_TAG"
                                                printf 'AI_WORKSPACE_IMAGE=%s\\n' "$IMAGE_TAG" >> artifacts/ai-workspace-images.env
                                            '''
                                        }
                                        successful << imageTag
                                        echo "Published ${imageTag}"
                                    } catch (Throwable variantFailure) {
                                        def message = variantFailure.message ?: variantFailure.toString()
                                        failed << "${variantPath}: ${message}"
                                        echo "Skipping ${variantPath} after failure: ${message}"
                                    } finally {
                                        reclaimDockerSpace(imageTag)
                                    }
                                }
                        } finally {
                            sh '''
                                set +e
                                docker logout >/dev/null 2>&1 || true
                            '''
                        }
                    }
                    writeFile file: 'artifacts/ai-workspace-build-report.txt', text: "Successful images (${successful.size()}):\\n${successful.join('\\n')}\\n\\nFailed images (${failed.size()}):\\n${failed.join('\\n')}\\n"
                    archiveArtifacts artifacts: 'artifacts/ai-workspace-images.env,artifacts/ai-workspace-build-report.txt', fingerprint: true
                    if (failed) {
                        currentBuild.result = 'UNSTABLE'
                        echo "${failed.size()} image build(s) failed; remaining images were processed."
                    }
                }
            }
        }
    }
}
