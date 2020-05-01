def templateLocalRelativePathYAML = 'ci/django-psql-example-template.yml'
def templateName = 'django-psql-example-ci' 
def templateApp = 'django-psql-example'
pipeline {

  options {
    timeout(time: 20, unit: 'MINUTES') 
  }

  agent any

// This pipeline (in conjunction with its accompanying openshift pipeline object) is loosely based on the OpenShift Pipeline Tutorial here:
// https://docs.openshift.com/online/dev_guide/dev_tutorials/openshift_pipeline.html
// 
// Documentation of the plugin syntax used below can be found in the markdown readme of the jenkins-client-plugin: 
// https://github.com/openshift/jenkins-client-plugin

  stages {
    stage('Stage 1: Populate') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject() {
              // First, let's make sure the template is new
              try {
                // Create template (will succeed if it doesn't yet appear in oc get template)
                openshift.create(readFile(templateLocalRelativePathYAML))
              } catch (err) {
                // If that failed, replace template, as it already appears in 'oc get template'
                openshift.replace(readFile(templateLocalRelativePathYAML))
              }
              // Next, clean out all objects labelled as belonging to templateApp
              openshift.selector( 'dc', [ app:templateApp ] ).delete()
              openshift.selector( 'bc', [ app:templateApp ] ).delete()
              openshift.selector( 'is', [ app:templateApp ] ).delete()
              openshift.selector( 'svc', [ app:templateApp ] ).delete()
              openshift.selector( 'route', [ app:templateApp ] ).delete()
              openshift.selector( 'secret', [ app:templateApp ] ).delete()
              // Finally, populate the project with the objects from the template:
              openshift.newApp(templateName, "-p", "DATABASE_USER=admin", "-p", "DATABASE_NAME=example", "-p", "DATABASE_PASSWORD=dummypassword", "-p", "SOURCE_REPOSITORY_URL=https://bitbucket.org/mikishapiro/django-ex.git")
            }
          }
        }
      }
    }

    stage('Stage 2: Build') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject() {
              def builds = openshift.selector("bc", [ app:templateApp ] ).related('builds')
              timeout(5) {
                builds.untilEach(1) {
                  return (it.object().status.phase == "Complete")
                }
              }
            }
          }
        }
      }
    }


    stage('Stage 3: Test') {
      steps {
        sh "echo 'Mock Test'"
        // DNS doesn't work properly on the cluster so the following (which does work off-cluster) returns Could not resolve host
        // sh "curl -I http://django-psql-example.apps.refarch.chorus-openshift-lab.net | grep 200"
      }
    }
    stage('Stage 4: Promote') {
      steps {
        sh "echo 'Waiting for user to review the deployment and promote the new version to production...'"
        // input id: 'Promote', message: 'Promote when ready', parameters: [string(defaultValue: '', description: '', name: 'promote_param')]
        input id: 'Promote', message: 'Promote when ready'
      }
    }
    stage('Stage 5: Tag Image') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject() {
              openshift.tag("${templateApp}:latest", "${templateApp}-staging:latest") 
            }
          }
        }
      }
    }
  }
}
