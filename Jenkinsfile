pipeline{

    agent { label 'CI_Agent' }

    tools {
        maven 'maven'
        // Use the fully qualified tool type for the Sonar scanner:

        'hudson.plugins.sonar.SonarRunnerInstallation' 'SonarScanner' 
        
        'dependency-check' 'OWASP-DC'

    }

    environment {
        ARTIFACT_ID = 'myapp'
        GROUP_ID = 'com.example'
        VERSION = '1.0.0'
        FILE_PATH = 'target/myapp.jar'
        NEXUS_URL = 'localhost:8081' 
        NEXUS_REPO = 'maven-releases'
        NEXUS_CREDENTIAL_ID = 'nexus-creds'
        SONARQUBE_ENV = 'SonarQube'
    }

    stages {

        stage('Cloning the Repository') {
            steps {
                git(
                    branch: 'main',
                    url: 'https://github.com/aniket270601/Boardgame.git',
                    credentialsId: 'GIT-PAT'
                )
            }
        }



        stage('Compile the code') {
            steps {
                
                    sh 'mvn compile'
                
            }
        }



        stage('OWASP Dependency Check') {
            steps {
                
                   script {
                    def dcHome = tool name: 'OWASP-DC', type: 'org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation'
                    withEnv(["PATH+DC=${dcHome}/bin"]) {
                        sh """
                            dependency-check.sh \
                            --project "MyApp" \
                            --scan . \
                            --format HTML \
                            
                        """
                    }
                }
                
            }
        }




        stage('SonarQube Code Analysis') {
            steps {

                withCredentials([string(credentialsId: 'SONAR_TOKEN_ID', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv("${env.SONARQUBE_ENV}") {
                        
                                sh '''
                                     /opt/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/SonarScanner/bin/sonar-scanner \
                                     -Dsonar.login=$SONAR_TOKEN
                                '''
                    }
                        
                    
                }
            }
        }




        stage('Run Unit Tests') {
            steps {
                
                    sh 'mvn test'
                
            }
        }



        stage('Build JAR File') {
            steps {
                
                    sh 'mvn package'
                
            }
        }


        stage ('Rename Artifact') {
            steps{

                dir('target') {

                    sh 'mv database_service_project-*.jar myapp.jar'

                }

            }
        }

    



        stage ('Pushing Artifact to Nexus Reository') {

            steps{
                
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: env.NEXUS_URL,
                        groupId: env.GROUP_ID,
                        version: env.VERSION,
                        repository: env.NEXUS_REPO,
                        credentialsId: env.NEXUS_CREDENTIAL_ID,
                        artifacts: [[
                            artifactId: env.ARTIFACT_ID,
                            file: env.FILE_PATH,
                            type: 'jar'
                        ]]
                    )

                
            }
        }




    }

}





