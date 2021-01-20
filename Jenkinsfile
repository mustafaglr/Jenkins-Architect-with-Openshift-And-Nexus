def openshiftBuildCredentials = "openshift_token_for_default_account_dev"
def openshiftDeployCredentials = "openshift_token_for_default_account_dev"
def openshiftTestCredentials = "openshift_token_for_default_account_test"
def openshiftDevCredentials = "openshift_token_for_default_account_dev"
def openshiftHfCredentials = "openshift_token_for_default_account_hf"
def openshiftProdCredentials = "openshift_token_for_default_account_prod"
def openshiftCredentials = "OPENSHIFT_USER"

def cluster = "CLUSTER" //default
def devOpsProject = "DEVOPS_PROJECT"
def project = "PROJECT"
def devProject = "webstore"
def testProject = "webstore-uat"
def hotfixProject = "webstore-hf" 


def profileName = ""
def pomGroupId = ""
def repoName = ""
def repoSubFolder = ""
def appName = ""
def routePath = ""
def hostName = ""
def memoryLimit = ""
def cpuLimit = ""

def nexusDockerRegistryUrl = "NEXUS_DOCKER_REGISTRY_URL/PROJECT_NAME"
def artifactUrlPrefix="http://NEXUS_URL/repository/REPOSITORY_NAME/"
def fromImage = "NEXUS_DOCKER_REGISTRY_URL/openjdk:8-jre-alpine"

def repoUrl = "BITBUCKET_PROJECT_URL_WITHOUT_REPOSITORY_NAME"
def bitbucketSshUrl = "BITBUCKET_SSH_URL_WITHOUT_REPOSITORY_NAME"
def devOpsUrl = "BITBUCKET_DEVOPS_PROJECT_HTTP_URL"
def devOpsUrlBranch = "master"
def branchName = ""

def jv_home = "$JAVA_HOME"

pipeline{
  agent any
    environment {
        //Environment variables for OpenShift plugin
        KUBERNETES_SERVICE_HOST = ''
        PROJECT_NAME = "${project}"
        SKIP_TLS = 'true'
    }

    stages {
        stage('Commit Stage') {
            steps {
                script {
                    //parameters

                  branchName = env.BRANCH_NAME
                  repoName = env.JOB_NAME.split('/')[2];
                  echo "${repoName}"
                  repoUrl = "${repoUrl}${repoName}.git"
                  bitbucketSshUrl = "${bitbucketSshUrl}${repoName}.git"
                  
		  		  
                  
                  if(branchName == "master"){
                    profileName = ""
                    project = devProject
                    openshiftBuildCredentials = openshiftDevCredentials
                    openshiftDeployCredentials = openshiftDevCredentials
                  }                  
                  if(branchName == "dev"){
                    profileName = "dev"
                    project = devProject
                    openshiftBuildCredentials = openshiftDevCredentials
                    openshiftDeployCredentials = openshiftDevCredentials
                  }
                  else if(branchName == "test"){
                    profileName = "test"
                    project = testProject
                    openshiftBuildCredentials = openshiftTestCredentials
                    openshiftDeployCredentials = openshiftTestCredentials
                  }
                  
                  else if(branchName == "hotfix"){
                    profileName = "hotfix"
                    project = hotfixProject
                    openshiftBuildCredentials = openshiftHfCredentials
                    openshiftDeployCredentials = openshiftHfCredentials
                  }
                  else if(branchName == "prod"){
                    profileName = "prod"
                    project = devProject
                    openshiftBuildCredentials = openshiftDevCredentials
                    openshiftDeployCredentials = openshiftProdCredentials
                    cluster = 'PROD_CLUSTER'
                  }
                  else{
                     profileName = ""
                     project = devProject
                     
                  }
                  
                  notifyStarted(repoName,branchName)
                  
                  def conf = readProperties  file: 'pipelineconfig'
                  routePath = conf['routePath']
                  appName = conf['appName']
				  memoryLimit = conf['memoryLimit']
                  cpuLimit = conf['cpuLimit']
                  
                  if (branchName == "master") {
	              	  hostName = conf['masterHostName']
                  }
                  if (branchName == "dev") {
                      hostName = conf['devHostName']
                  }
                  if (branchName == "test") {
                 	 hostName = conf['testHostName']
                  }
                  if (branchName == "hotfix") {
                  	 hostName = conf['hfHostName']
                  }
              	  if (branchName == "prod") {
                     hostName = conf['prodHostName']
                  }
                  
                  
                  dir('devops') {
                              git(url: "${devOpsUrl}", branch: "${devOpsUrlBranch}", credentialsId: "${openshiftCredentials}")
                  }                    
                    
                  stash includes: "devops/OpenShiftTemplates/**/*", name: 'osTemplates'

                  def pom = readMavenPom file: "${repoSubFolder}pom.xml"
                  artifactId = pom.artifactId
                  pomGroupId = pom.groupId
                  pomGroupId = pomGroupId.replace(".", "/")
		  appVersion = "${branchName}-${currentBuild.number}"
                  env.TAG_VERSION = "${pom.version}"
                  
                  configFileProvider([configFile(fileId: '', variable: 'MAVEN_SETTINGS_XML'),
                                       configFile(fileId: '', variable: 'MAVEN_SETTINGS_2_XML')]) {
                      
                        withEnv(["JAVA_HOME=${jv_home}"]) {
                          sh "mvn clean install -f ${repoSubFolder}pom.xml -B -Dmaven.test.failure.ignore -s $MAVEN_SETTINGS_XML -DskipTests -Dversion=${appVersion}"
                          sh "mvn deploy -s $MAVEN_SETTINGS_XML -f ${repoSubFolder}pom.xml -DskipTests -Dversion=${appVersion}"
                       
                        }
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
                      configFileProvider([configFile(fileId: '', variable: 'MAVEN_SETTINGS_XML')]) {
                         sh "mvn sonar:sonar -s $MAVEN_SETTINGS_XML -f ${repoSubFolder}pom.xml"
                      }
                  }
               }
            }
        }

        stage('Building Docker Container') {
            steps {
                unstash 'osTemplates'
                script {
                    openshiftAppName = "${appName}"
                    openshift.withCluster( 'cloudmbdevui', "${openshiftBuildCredentials}" ){
                    	openshift.withProject(project) {
			    openshift.apply(openshift.process(readFile(file: "devops/OpenShiftTemplates/base-template.yaml"), "-p", "APP_NAME=${openshiftAppName}", "-p", "APP_VERSION=${appVersion}", "-p", "SOURCE_REPOSITORY_URL=${bitbucketSshUrl}", "-p", "BRANCH_NAME=${branchName}", "-p", "REGISTRY_URL=${nexusDockerRegistryUrl}", "-p", "NAME=${appName}"))
                        	
                            print "ARTIFACT URL:"
                            artifactUrl = artifactUrlPrefix + pomGroupId + "/${artifactId}/${appVersion}/${artifactId}-${appVersion}.jar"
                            print artifactUrl
                                      
                            openshift.raw("set env bc ${appName} APP_NAME=${artifactId} APP_VERSION=${appVersion}  BRANCH_NAME=${branchName}")
                        		    
                            openshift.startBuild("${appName}", '--from-dir .', '--follow')
                        }
                    }
                }
            }
        }



        stage('Deploying to Cluster') {
            steps {
                  echo "Deploy is started!"
                  unstash 'osTemplates'
                  script {
                    openshiftAppName = "${appName}"
                    openshift.withCluster( "${cluster}", "${openshiftDeployCredentials}" ){
                        openshift.withProject(project) {
                                openshift.apply(openshift.process(readFile(file: "devops/OpenShiftTemplates/deployment-template.yaml"),"-p", "MEMORY_LIMIT=${memoryLimit}","-p", "CPU_LIMIT=${cpuLimit}","-p", "APP_NAME=${openshiftAppName}", "-p", "APP_VERSION=${appVersion}", "-p", "ROUTE_PATH=${routePath}", "-p", "PROFILE_NAME=${profileName}", "-p", "NAME=${appName}", "-p", "REGISTRY_URL=${nexusDockerRegistryUrl}", "-p", "NAMESPACE=${project}", "-p", "HOST_NAME=${hostName}"))
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
