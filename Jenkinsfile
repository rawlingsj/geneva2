pipeline {
    agent {
        label "jenkins-go"
    }
    environment {
      ORG               = 'jenkins-x-bot'
      APP_NAME          = 'geneva2'
      GIT_PROVIDER      = 'github.com'
      CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    }
    stages {
      stage('CI Build and push snapshot') {
        when {
          branch 'PR-*'
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/jenkins-x-bot/geneva2') {
            checkout scm
            container('go') {
              sh "make linux"
              sh 'export VERSION=$PREVIEW_VERSION && skaffold run -f skaffold.yaml'

              sh "jx step post build --image \$JENKINS_X_DOCKER_REGISTRY_SERVICE_HOST:\$JENKINS_X_DOCKER_REGISTRY_SERVICE_PORT/$ORG/$APP_NAME:$PREVIEW_VERSION"
            }
          }
          dir ('/home/jenkins/go/src/github.com/jenkins-x-bot/geneva2/charts/preview') {
            container('go') {
              sh "make preview"
              sh "jx preview --app $APP_NAME --dir ../.."
            }
          }
        }
      }
      stage('Build Release') {
        when {
          branch 'master'
        }
        steps {
          container('go') {
            dir ('/home/jenkins/go/src/github.com/jenkins-x-bot/geneva2') {
              checkout scm
              // so we can retrieve the version in later steps
              sh "echo \$(jx-release-version) > VERSION"
            }
            dir ('/home/jenkins/go/src/github.com/jenkins-x-bot/geneva2/charts/geneva2') {
                // ensure we're not on a detached head
                sh "git checkout master"
                // until we switch to the new kubernetes / jenkins credential implementation use git credentials store
                sh "git config --global credential.helper store"
                sh "jx step git credentials"

                sh "make tag"
            }
            dir ('/home/jenkins/go/src/github.com/jenkins-x-bot/geneva2') {
              container('go') {
                sh "make build"
                sh 'export VERSION=`cat VERSION` && skaffold run -f skaffold.yaml'
                sh "jx step post build --image \$JENKINS_X_DOCKER_REGISTRY_SERVICE_HOST:\$JENKINS_X_DOCKER_REGISTRY_SERVICE_PORT/$ORG/$APP_NAME:\$(cat VERSION)"
              }
            }
          }
        }
      }
      stage('Promote to Environments') {
        when {
          branch 'master'
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/jenkins-x-bot/geneva2/charts/geneva2') {
            container('go') {
              sh 'jx step changelog --version v\$(cat ../../VERSION)'

              // release the helm chart
              sh 'make release'

              // promote through all 'Auto' promotion Environments
              sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)'
            }
          }
        }
      }
    }
    post {
        always {
            cleanWs()
        }
    }
  }
