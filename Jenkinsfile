def openshiftDevOpsCredentials = "openshift_token_for_default_account"
def devOpsProject = "DEVOPS_PROJECT"
def profileName = ""
def project = "PROJECT"
def openshiftCredentials = "OPENSHIFT_USER"
def artifactUrlPrefix="http://NEXUS_URL/repository/REPOSITORY_NAME/"
def pomGroupId = ""
def devOpsUrl = "BITBUCKET_DEVOPS_PROJECT_HTTP_URL"
def devOpsUrlBranch = "master"
def branchName = ""
def repoName = ""
def repoSubFolder = ""
def appName = ""
def nexusDockerRegistryUrl = "NEXUS_DOCKER_REGISTRY_URL/PROJECT_NAME"
def repoUrl = "BITBUCKET_PROJECT_URL_WITHOUT_REPOSITORY_NAME"
def bitbucketSshUrl = "BITBUCKET_SSH_URL_WITHOUT_REPOSITORY_NAME"
def routePath = ""
def hostName = ""

pipeline{
  agent {label 'maven'}
    environment {
        //Environment variables for OpenShift plugin
        KUBERNETES_SERVICE_HOST = ''
        PROJECT_NAME = "${project}"
        SKIP_TLS = 'true'
    }

    stages {
        stage('Commit Stage') {
        	when {
		    expression {
		        return env.BUILD_NUMBER != '1';
		        }
		    }
            steps {
                script {
                    //parameters

                  branchName = env.BRANCH_NAME
                  repoName = env.JOB_NAME.split('/')[2];
                  echo "${repoName}"
                  repoUrl = "${repoUrl}${repoName}.git"
                  bitbucketSshUrl = "${bitbucketSshUrl}${repoName}.git"
				  notifyStarted(repoName,branchName)
                  if(branchName == "master"){
                    profileName = "test"
                  }
                  if(branchName == "dev"){
                    profileName = "dev"
                  }
                  if(branchName == "prod"){
                    profileName = "prod"
                  }

                  def conf = readProperties  file: 'pipelineconfig'
                  routePath = conf['routePath']
                  appName = conf['appName']

                  if (branchName == "development") {
	          	       hostName = conf['devHostName']
	          	   }
	          	  if (branchName == "master") {
		          	   hostName = conf['testHostName']
	          	   }
			  	  if (branchName == "prod") {
	          	       hostName = conf['prodHostName']
	               }
					dir('devops') {
                      git(url: "${devOpsUrl}", branch: "${devOpsUrlBranch}", credentialsId: "${openshiftCredentials}")
				    }
				    print pwd
			        stash includes: "devops/OpenShiftTemplates/**/*", name: 'osTemplates'
					def pom = readMavenPom file: "${repoSubFolder}pom.xml"
                    artifactId = pom.artifactId
                    print "GROUP ID"
                    pomGroupId = pom.groupId
                    print pomGroupId
                    pomGroupId = pomGroupId.replace(".", "/")
                    print pomGroupId
					appVersion = "${branchName}-${currentBuild.number}"
                    echo "appName: ${appName}"
                    echo "appVersion ${appVersion}"
                    env.TAG_VERSION = "${pom.version}"
                    configFileProvider([configFile(fileId: '11c4b96d-4fec-4599-983f-abbc76085ef1', variable: 'MAVEN_SETTINGS_XML'),
                                       configFile(fileId: '765e29a7-d68d-46e4-991c-b9dee8216d6a', variable: 'MAVEN_SETTINGS_PRI_XML')]) {
                        sh "mvn clean install -f ${repoSubFolder}pom.xml -B -Dmaven.test.failure.ignore -s $MAVEN_SETTINGS_XML -DskipTests -Dversion=${appVersion}"
                        sh "mvn deploy -s $MAVEN_SETTINGS_PRI_XML -f ${repoSubFolder}pom.xml -DskipTests -Dversion=${appVersion}"
                    }
                }
            }
        }

       stage('Sonar Analysis') {
            steps {
                script {
                  def projectKey = "${appName}-${branchName}"
                  def binaryPath = "${repoSubFolder}target/classes"
                  def sources = "${repoSubFolder}src"
                  if(branchName != "prod"){
                	  print "Sonar Analysis is started!"
                      configFileProvider([configFile(fileId: '11c4b96d-4fec-4599-983f-abbc76085ef1', variable: 'MAVEN_SETTINGS_XML')]) {
                         sh "mvn sonar:sonar -s $MAVEN_SETTINGS_XML -f ${repoSubFolder}pom.xml"
                      }
                  }
               }
            }
        }


        stage('Building Docker Container') {

            when {
		    expression {
		        return env.BUILD_NUMBER != '1';
		        }
		    }
            steps {
                unstash 'osTemplates'
                script {
                    openshiftAppName = "${appName}"
                    openshift.withCluster( 'cloudmbdevui', 'openshift_token_for_default_account' ){
                    	openshift.withProject(project) {
						             openshift.apply(openshift.process(readFile(file: "devops/OpenShiftTemplates/base-template.yaml"), "-p", "APP_NAME=${openshiftAppName}", "-p", "APP_VERSION=${appVersion}", "-p", "SOURCE_REPOSITORY_URL=${bitbucketSshUrl}", "-p", "BRANCH_NAME=${branchName}", "-p", "REGISTRY_URL=${nexusDockerRegistryUrl}", "-p", "NAME=${appName}"))
                        }
                  	}
                  	print "ARTIFACT URL:"
                  	artifactUrl = artifactUrlPrefix + pomGroupId + "/${artifactId}/${appVersion}/${artifactId}-${appVersion}.jar"
                  	print artifactUrl

                    withCredentials([usernamePassword(credentialsId: "${openshiftCredentials}", usernameVariable: 'NUSER', passwordVariable: 'NPASS')]) {
                       sh """
                       oc login --insecure-skip-tls-verify ${KUBERNETES_SERVICE_HOST} -u ${NUSER} -p ${NPASS}
                       oc project ${project}
                       oc set env bc ${appName} APP_NAME=${artifactId} APP_VERSION=${appVersion}
                       oc start-build ${appName} --from-dir ${repoSubFolder}. --follow """
                     }
                }
            }
        }



        stage('Deploying to Dev Env') {
            when {
		    expression {
		        return env.BUILD_NUMBER != '1';
		        }
		    }
            steps {
			    echo "Deploy is started!"
                unstash 'osTemplates'
                script {
                if (branchName != "prod" ) {
                    openshiftAppName = "${appName}"
                    openshift.withCluster( 'cloudmbdevui', 'openshift_token_for_default_account' ){
                      openshift.withProject(project) {
                      		openshift.apply(openshift.process(readFile(file: "devops/OpenShiftTemplates/deployment-template.yaml"), "-p", "APP_NAME=${openshiftAppName}", "-p", "APP_VERSION=${appVersion}", "-p", "ROUTE_PATH=${routePath}", "-p", "PROFILE_NAME=${profileName}", "-p", "NAME=${appName}", "-p", "REGISTRY_URL=${nexusDockerRegistryUrl}", "-p", "NAMESPACE=${project}",  "-p", "HOST_NAME=${hostName}"))
                      }
                    }
                }else{
                  openshift.withCluster( 'ocpvfesyui', 'openshift_token_for_default_account_prod' ){
                      openshift.withProject(project) {
                      		openshift.apply(openshift.process(readFile(file: "devops/OpenShiftTemplates/deployment-template.yaml"), "-p", "APP_NAME=${openshiftAppName}", "-p", "APP_VERSION=${appVersion}", "-p", "ROUTE_PATH=${routePath}", "-p", "PROFILE_NAME=${profileName}", "-p", "NAME=${appName}", "-p", "REGISTRY_URL=${nexusDockerRegistryUrl}", "-p", "NAMESPACE=${project}",  "-p", "HOST_NAME=${hostName}"))
                      }
                   }
                }
            }
        }

        post {
            success {
                script {
                    if (env.BUILD_NUMBER != '1') {
                       notifySuccessful(repoName,branchName)
                    }
                }
            }
             failure {
                script {
                    if (env.BUILD_NUMBER != '1') {
                       notifyFailed(repoName,branchName)
                   }
                }
            }
        }
      }
    }

}


def notifyStarted(String repoName,String branchName) {
  emailext body: "STARTED",
        mimeType: 'text/html',
        subject: "[Jenkins] ${repoName}-${branchName}-${currentBuild.number} - STARTED",
        to: "",
        replyTo: "",
        recipientProviders: [[$class: 'CulpritsRecipientProvider']]
}

def notifySuccessful(String repoName,String branchName) {
  emailext body: '''${SCRIPT, template="groovy-html.template"}''',
        mimeType: 'text/html',
        subject: "[Jenkins] ${repoName}-${branchName}-${currentBuild.number} - SUCCEED",
        to: "",
        replyTo: "",
        recipientProviders: [[$class: 'CulpritsRecipientProvider']]
}

def notifyFailed(String repoName,String branchName) {
  emailext body: '''${SCRIPT, template="groovy-html.template"}''',
        mimeType: 'text/html',
        subject: "[Jenkins] ${repoName}-${branchName}-${currentBuild.number} - FAILED",
        to: "",
        replyTo: "",
        recipientProviders: [[$class: 'CulpritsRecipientProvider']]
}
