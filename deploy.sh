#!/usr/bin/env bash

# Usage:
# deploy.sh test|prod install|upgrade
if [[ "$#" != 2 ]]; then
  echo "Usage: $0 test|prod install|upgrade|delete"
  exit 1
fi

ENVNAME=${1:-test}
ACTION=${2:-install}
mkdir -p ./helm/${ENVNAME}

#########################################################################################
#environment configuration
#########################################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GREEN_PS3=$'\e[0;32m'
ORANGE_PS3=$'\e[0;33m'
WHITE='\033[0;37m'
if [ -z "${KUBECONFIG}" ]; then
    export KUBECONFIG=~/.kube/config
fi

if [ -z "${NAMESPACE}" ]; then
    NAMESPACE=monitoring
fi

if [[ "${ACTION}" != "delete" ]]; then
    ##########################################################################################################################################
    #configure alert channels
    ##########################################################################################################################################
    #SMTP
    echo
    echo -e "${BLUE}Do you want to set up an SMTP relay?"
    tput sgr0
    read -p "Y/N [N]: " use_smtp

    #if so, fill out this form...
    if [[ $use_smtp =~ ^([yY][eE][sS]|[yY])$ ]]; then
      #smtp smarthost
      read -p "SMTP smarthost: " smtp_smarthost
      #smtp from address
      read -p "SMTP from (user@domain.com): " smtp_from
      #smtp to address
      read -p "Email address to send alerts to (user@domain.com): " alert_email_address
      #smtp username
      read -p "SMTP auth username: " smtp_user
      #smtp password
      prompt="SMTP auth password: "
      while IFS= read -p "$prompt" -r -s -n 1 char
      do
          if [[ $char == $'\0' ]]
          then
              break
          fi
          prompt='*'
          smtp_password+="$char"
      done

      #update configmap with SMTP relay info
      sed -i -e 's/your_smtp_smarthost/'"$smtp_smarthost"'/g' \
        -e 's/your_smtp_from/'"$smtp_from"'/g' \
        -e 's/your_smtp_user/'"$smtp_user"'/g' \
        -e 's,your_smtp_pass,'"$smtp_password"',g' \
        -e 's/your_alert_email_address/'"$alert_email_address"'/g' \
        ./assets/alertmanager/alertmanager.yaml >./helm/${ENVNAME}/prometheus-add-alertmanager.yaml
    fi

    #Do you want to set up slack?
    echo
    echo -e "${BLUE}Do you want to set up slack alerts?"
    tput sgr0
    read -p "Y/N [N]: " use_slack

    #if so, fill out this form...
    if [[ $use_slack =~ ^([yY][eE][sS]|[yY])$ ]]; then

      read -p "Slack api token (portion after 'https://hooks.slack.com/services/'): " slack_api_token
      read -p "Slack channel (no #): " slack_channel

      #again, our sed is funky due to slashes appearing in slack api tokens
      sed -e 's,your_slack_api_token,'"$slack_api_token"',g' \
        -e 's/your_slack_channel/'"$slack_channel"'/g' \
        ./assets/alertmanager/alertmanager.yaml >./helm/${ENVNAME}/prometheus-add-alertmanager.yaml
    fi


    ######################################################################################################
    #deploy all the components
    ######################################################################################################


    helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
    helm repo update
    tput sgr0
    # This is a horrible hack.
    # Until prometheus-operator releases > v0.19.0
    # https://github.com/coreos/prometheus-operator/pull/1338
    read -r -d '' ALERTMANAGER_YAML < <(cat ./helm/${ENVNAME}/prometheus-add-alertmanager.yaml | sed 's/^/    /')
    export ALERTMANAGER_YAML
    export ENVNAME
    read -r -d '' KUBE_PROMETHEUS_VALUES_TEMPLATE < ./helm/kube-prometheus-values-env.yaml
    eval KUBE_PROMETHEUS_VALUES="\"$KUBE_PROMETHEUS_VALUES_TEMPLATE\""

    echo "$KUBE_PROMETHEUS_VALUES" >./helm/${ENVNAME}/kube-prometheus-values.yaml
fi

if [[ "${ACTION}" == "install" ]]; then
  echo -e "${ORANGE}Helm installing prometheus-operator"
  tput sgr0
  helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring
  echo -e "${ORANGE}Kubectl creating additional-scrape-configs secret"
  tput sgr0
  kubectl create secret generic additional-scrape-configs --from-file=./helm/prometheus-add-scrape.yaml --dry-run -oyaml > ./helm/${ENVNAME}/additional-scrape-configs.yaml
  kubectl apply -f ${ENVNAME}/additional-scrape-configs.yaml
  # Until  prometheus-operator releases > v0.19.0
  # kubectl create secret generic additional-alertmanager-configs --from-file=./helm/${ENVNAME}/prometheus-add-alertmanager.yaml --dry-run -oyaml > ./helm/${ENVNAME}/additional-alertmanager-configs.yaml
  # kubectl apply -f ./helm/${ENVNAME}/additional-alertmanager-configs.yaml.yaml
  echo -e "${ORANGE}Helm installing kube-prometheus"
  tput sgr0
  helm install coreos/kube-prometheus \
  --name kube-prometheus \
  --namespace monitoring \
  -f ./helm/${ENVNAME}/kube-prometheus-values.yaml
elif [[ "${ACTION}" == "upgrade" ]]; then
  echo -e "${ORANGE}Helm upgrading kube-prometheus"
  tput sgr0
  helm upgrade prometheus-operator coreos/kube-prometheus \
  --name kube-prometheus \
  --namespace monitoring \
  -f ./helm/${ENVNAME}/kube-prometheus-values.yaml
elif [[ "${ACTION}" == "delete" ]]; then
  echo -e "${ORANGE}Helm deleting kube-prometheus"
  tput sgr0
  helm delete kube-prometheus --purge
  echo -e "${ORANGE}Helm deleting prometheus-operator"
  tput sgr0
  helm delete prometheus-operator --purge
fi
