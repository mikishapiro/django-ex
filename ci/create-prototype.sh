#!/bin/bash 
set +x
app_name=django-psql-example
prototype_project=${app_name}-prototype
oc whoami || oc login
echo "Cleaning out existing project..."
oc delete project/${prototype_project}

echo "Waiting for clean to complete..."
while oc projects |grep -w ${prototype_project} >/dev/null 2>&1; do
  sleep 1 
done 

echo "Creating new project..."
while ! oc new-project ${prototype_project} 2>/dev/null  ; do 
  echo "Can't create a new project yet. Waiting 10 seconds and trying again..."
  sleep 10
done

echo "Waiting for new project to be ready..."
while ! oc project 2>/dev/null |grep -w ${prototype_project} >/dev/null 2>&1; do
  sleep 1
done 2>&1 >/dev/null

sleep 10

oc new-app --template=django-psql-example \
      -p DATABASE_USER=admin \
      -p DATABASE_NAME=example \
      -p DATABASE_PASSWORD=dummypassword \
      -p SOURCE_REPOSITORY_URL=https://bitbucket.org/mikishapiro/django-ex.git

oc export bc/django-psql-example |sed 's/^  nodeSelector: null/  nodeSelector: {}/'|oc replace -f - 
oc export bc/django-psql-example |sed 's/^  runPolicy: Serial/  runPolicy: SerialLatestOnly/'|oc replace -f -
oc start-build django-psql-example

# The right way to do this is by fixing DNS and polling the service like so:
# while ! curl -I http://`oc get route django-psql-example |awk '{print $2}'|tail -1`|grep 200; do sleep 1 ; done

# Until then, a workaround (monitor the service for the appearance of valid endpoints that have a colon in them:
while ! oc describe service ${app_name} |awk '/Endpoints/{print $2}'|grep : ; do sleep 1 ; done
# End of workaround

echo "Ready!"
echo "What to do now:"
echo "1. Run any last rites on this environment prior to bundling it up into a template"
echo "2. To create the template, run:"
echo ""
echo "      oc export is,dc,bc,svc,route,secret --as-template ${app_name}-ci -o yaml  > ${app_name}-template.yml."
echo ""
echo "3. The following sections need to be manually removed from ${app_name}-template.yml:"
echo "  * All sections titled 'namespace: ${prototype_project}' and whatever is underneath them"
echo "  * All sections titled 'status' and whatever is underneath them"
echo "  * All lines titled 'creationTimestamp'" 
echo "  * The 'host:' line under Route object(s)."
echo "  * The 'tags:' section under ImageStreams object(s)"
echo "4. Add the parameters section from the original template. The oc export command didn't bring them along for the ride. Fastest way:"
echo "      ssh ocp-master1.example.com sudo sh -c \' oc project openshift \; oc export template ${app_name} \' |grep '^parameters:$' -A10000 >> ${app_name}-template.yml"
echo ""
echo "5. Push the template to git by running:"
echo ""
echo "      git add ${app_name}-template.yml ; git commit -m 'Changed template' ; git push"
echo ""
echo "Once done, (presuming your oc command is still logged in), you can set up an instance of the pipeline by running:"
echo "      ansible-playbook ./pipeline-deploy-playbook.yml"
