# Jenkins Architecture with Openshift and Nexus

## The life cycle of proccess : 

![Arc](https://github.com/mustafaglr/Jenkins-Architecture-with-Openshift-And-Nexus/blob/master/images/arcforgithub-1.jpg)

## Explanation of life cycle : 

![Arc-1](https://github.com/mustafaglr/Jenkins-Architecture-with-Openshift-And-Nexus/blob/master/images/arcforgithub-2.jpg)

## Must Change on Project : 

![Arc-3](https://github.com/mustafaglr/Jenkins-Architecture-with-Openshift-And-Nexus/blob/master/images/arcforgithub-3.jpg)

![Arc-4](https://github.com/mustafaglr/Jenkins-Architecture-with-Openshift-And-Nexus/blob/master/images/arcforgithub-4.jpg)

## Load Generic pipeline which is stored on Devops project

![Arc-5](https://github.com/mustafaglr/Jenkins-Architecture-with-Openshift-And-Nexus/blob/master/images/arcforgithub-5.jpg)

"JenkinsfileInBranch" is in the every branch of every project. It only loads Generic Pipeline which is stored on Devops project. Every changes on Generic Pipeline will be applied when "JenkinsfileInBranch" is running. Because "JenkinsfileInBranch" only loads.

## Change variables to use correctly

#### Jenkinsfile :  
    DEVOPS_PROJECT  
    PROJECT  
    OPENSHIFT_USER  
    NEXUS_URL  
    REPOSITORY_NAME  
    BITBUCKET_DEVOPS_PROJECT_HTTP_URL  
    NEXUS_DOCKER_REGISTRY_URL  
    PROJECT_NAME  
    BITBUCKET_PROJECT_URL_WITHOUT_REPOSITORY_NAME  
    BITBUCKET_SSH_URL_WITHOUT_REPOSITORY_NAME  
    "fill 'KUBERNETES_SERVICE_HOST' "  
  
#### JenkinsfileInBranch :  
    CREDENTIALS_ID  
    BITBUCKET_DEVOPS_PROJECT_HTTP_URL  
  
#### Dockerfileui :  
    NEXUS_USERNAME  
    NEXUS_PASSWORD     
  
# ENJOY!

