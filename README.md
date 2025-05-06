# CI/CD Pipeline Setup with Jenkins, SonarQube, Nexus, Docker, Terraform, Ansible, Prometheus, and Grafana

This repository contains Java based application which will be hosted on amazon application load balancer. The OWASP-DC and SonaraQube code analysis will also be performed on source code. As a result, application will be built using Maven and then executable binary will be pushed to Nexus repository to store build artifact in CI part.
In CD Part, Terraform (main.tf) will provision the application server (on which application will be hosted). It will aslo provision amazon application load balancer. Ansible (appserver.yml) will make configutation changes and install required dependencies to run application. The provisioned application server will then be registered as prometheus target via ansible and then Grafana will pull the metrics from prometheus data source.


## Prerequisites

You need the following Ubuntu-based machines set up:

1. **Jenkins Controller** – to install Jenkins
2. **Jenkins Agent** – to run Jenkins jobs
3. **SonarQube Server** – to perform code quality analysis
4. **Monitoring Server** – to install Prometheus and Grafana for real-time monitoring

---

## Plan of Action

### 1. Install Java JDK

* Install Java JDK 17 or newer on the Jenkins Controller and Agent machines.

### 2. Install Jenkins

* Follow the [official Jenkins installation guide](https://www.jenkins.io/doc/book/installing/) to install Jenkins on the Jenkins Controller machine.
* Access the Jenkins UI at:

  ```
  http://<public-ip-of-controller>:8080
  ```

### 3. Setup Jenkins Agent

* Prepare a separate Ubuntu machine.
* Install the same Java version as the Controller.
* Install Docker and run Nexus Repository:

  ```bash
  sudo docker run -d --name nexus -p 8081:8081 sonatype/nexus3
  ```
* Access Nexus via:

  ```
  http://<agent-public-ip>:8081
  ```
* Complete initial setup and enable anonymous access.

### 4. Connect Jenkins Agent

* On Jenkins UI:

  * Go to **Manage Jenkins → Nodes → New Node**.
  * Enter the agent details.
  * Use SSH credentials for connecting the agent.
* The agent should appear as online after successful configuration.

### 5. Setup SonarQube Server

* Install SonarQube on a dedicated Ubuntu machine.
* Configure SonarQube as a systemd service to run on boot.
* Access via:

  ```
  http://<sonarqube-ip>:9000
  ```

### 6. Install Jenkins Plugins

* Go to **Manage Jenkins → Plugins**.
* Install the following plugins:

  * OWASP Dependency-Check
  * SonarQube Scanner for Jenkins
  * Nexus Artifact Uploader
  * Pipeline Utility Steps

### 7. Configure Jenkins Tools

* **SonarQube Scanner**:

  * Name: `SonarScanner`
  * Install from Maven Central

* **Maven**:

  * Name: `maven`

* **Dependency-Check**:

  * Name: `OWASP-DC`
  * Install from GitHub

### 8. Configure SonarQube in Jenkins

* Go to **Manage Jenkins → Global Tool Configuration**.
* Add a new SonarQube installation:

  * Name: `SonarQube`
  * Server URL: `http://<sonarqube-ip>:9000`
  * Enable *Environment variables*.
  * Leave *Server authentication token* blank (use Jenkins credentials instead).

### 9. Add Jenkins Credentials

Go to **Manage Jenkins → Credentials → Global** and add:

* **GitHub PAT** (Kind: Username with Password):

  * ID: `GIT-PAT`
  * Username: `<github-username>`
  * Password: `<personal-access-token>`

* **SonarQube Token** (Kind: Secret Text):

  * ID: `SONAR_TOKEN_ID`
  * Secret: `<sonarqube-token>`

* **Nexus Credentials** (Kind: Username with Password):

  * ID: `nexus-creds`
  * Username: `admin`
  * Password: `nexus`

* **Jenkins Agent Credentials** (Kind: SSH Username with Private Key):

  * ID: `CI_Agent-creds`

### 10. Setup AWS Credentials for Terraform

* On the Jenkins Agent machine:

  ```bash
  sudo vim ~/.bashrc
  ```

  Add:

  ```bash
  export AWS_ACCESS_KEY_ID=<your-access-key-id>
  export AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
  ```

  Then run:

  ```bash
  source ~/.bashrc
  ```
* Terraform will now automatically pick up these credentials in each shell session.

### 11. Create Jenkins CI Job

* From the Jenkins Dashboard:

  * Click **New Item**
  * Select **Pipeline**, click **OK**
  * In **Pipeline → Definition**, choose **Pipeline script from SCM**
  * Select SCM (e.g., Git), enter repository URL and credentials
  * In **Script Path**, enter path to the Jenkinsfile (e.g., `Jenkinsfile` or `ci/Jenkinsfile`)
  * The CI Jenkinsfile is saved in the **CI branch** of current repo
  * Click **Save**

### 12. Create Jenkins CD Job

* Follow the same steps as CI job
* Use Jenkinsfile from the **CD branch** of current repo
* In job configuration:

  * Enable **Build after other projects are built** to trigger after CI success

### 13. Install Terraform and Ansible on Jenkins Agent

* On the agent machine:

  ```bash
  sudo apt install terraform ansible -y
  ```

### 14. Trigger the Pipeline

* Run the CI job. It should automatically trigger the CD job.
* The application will be deployed on a load balancer created by Terraform.

### 15. Access the Deployed Application

* Copy the DNS of the load balancer from Terraform output.
* Open in browser (with `http://` prefix).
* You will also be able to see sonarqube code analysis at http://<sonarqube-ip>:9000

### 16. Prometheus & Grafana Monitoring Setup

* Access Prometheus targets at:

  ```
  http://<monitoring-ip>:9090/targets
  ```
* Confirm the app server is listed as a target.
* Access Grafana at:

  ```
  http://<monitoring-ip>:3000
  ```
* Add Prometheus as a data source ([http://localhost:9090](http://localhost:9090))
* Import Dashboard ID `1860` for Node Exporter metrics.

You now have a full CI/CD and monitoring pipeline setup using Jenkins, Nexus, SonarQube, Terraform, Prometheus, and Grafana.
