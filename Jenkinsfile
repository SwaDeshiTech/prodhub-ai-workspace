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
        string(name: 'DOCKER_REGISTRY_URL', defaultValue: 'https://index.docker.io/v1/', description: 'Registry URL used for Docker login')
        string(name: 'DOCKER_CREDENTIAL_ID', defaultValue: '', description: 'Jenkins username/password credential for the registry')
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
                    def registryHost = params.DOCKER_REGISTRY_URL.trim()
                        .replaceFirst(/^https?:\/\//, '')
                        .split('/', 2)[0]
                        .split(':', 2)[0]
                    def dockerHubHost = ['docker.io', 'index.docker.io', 'registry-1.docker.io'].contains(registryHost)
                    def imageRepositoryWithRegistry = dockerHubHost ? imageRepository : "${registryHost}/${imageRepository}"
                    def successful = []
                    def failed = []
                    sh '''
                        set -eu
                        mkdir -p artifacts
                        : > artifacts/ai-workspace-images.env
                    '''
                    withCredentials([usernamePassword(credentialsId: params.DOCKER_CREDENTIAL_ID.trim(), usernameVariable: 'REGISTRY_USERNAME', passwordVariable: 'REGISTRY_PASSWORD')]) {
                        withEnv(["REGISTRY_LOGIN_URL=${params.DOCKER_REGISTRY_URL.trim()}"]) {
                            sh '''
                                set -eu
                                export DOCKER_CONFIG="$WORKSPACE/.docker"
                                mkdir -p "$DOCKER_CONFIG"
                                printf '%s' "$REGISTRY_PASSWORD" | docker login "$REGISTRY_LOGIN_URL" --username "$REGISTRY_USERNAME" --password-stdin
                            '''
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
                                    def imageTag = "${imageRepositoryWithRegistry}:ai-workspace-${variantName}"
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
                                                docker image rm -f "$IMAGE_TAG" || true
                                            '''
                                        }
                                        successful << imageTag
                                        echo "Published ${imageTag}"
                                    } catch (Throwable variantFailure) {
                                        def message = variantFailure.message ?: variantFailure.toString()
                                        failed << "${variantPath}: ${message}"
                                        echo "Skipping ${variantPath} after failure: ${message}"
                                        withEnv(["IMAGE_TAG=${imageTag}"]) {
                                            sh 'docker image rm -f "$IMAGE_TAG" || true'
                                        }
                                    }
                                }
                            } finally {
                                sh '''
                                    set +e
                                    export DOCKER_CONFIG="$WORKSPACE/.docker"
                                    docker logout "$REGISTRY_LOGIN_URL" >/dev/null 2>&1 || true
                                '''
                            }
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
