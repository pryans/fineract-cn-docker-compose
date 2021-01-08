#!/bin/bash -ex

function init-variables {
    CASSANDRA_REPLICATION_TYPE="Simple"
    CASSANDRA_CONTACT_POINTS="UNKNOWN"
    CASSANDRA_CLUSTER_NAME="datacenter1"
    CASSANDRA_REPLICAS="1"

    POSTGRES_DRIVER_CLASS="org.postgresql.Driver"
    POSTGRES_HOST="postgres"
    POSTGRES_PWD="postgres"
    POSTGRESQL_PORT="5432"
    POSTGRESQL_USER="postgres"

    PROVISIONER_URL="UNKNOWN"
    IDENTITY_URL="UNKNOWN"
    RHYTHM_URL="UNKNOWN"
    OFFICE_URL="UNKNOWN"
    CUSTOMER_URL="UNKNOWN"
    ACCOUNTING_URL="UNKNOWN"
    PORTFOLIO_URL="UNKNOWN"
    DEPOSIT_URL="UNKNOWN"
    TELLER_URL="UNKNOWN"
    REPORT_URL="UNKNOWN"
    CHEQUES_URL="UNKNOWN"
    PAYROLL_URL="UNKNOWN"
    GROUP_URL="UNKNOWN"
    NOTIFICATIONS_URL="UNKNOWN"

    MS_VENDOR="Apache Fineract"
    IDENTITY_MS_NAME="identity-v1"
    RHYTHM_MS_NAME="rhythm-v1"
    OFFICE_MS_NAME="office-v1"
    CUSTOMER_MS_NAME="customer-v1"
    ACCOUNTING_MS_NAME="accounting-v1"
    PORTFOLIO_MS_NAME="portfolio-v1"
    DEPOSIT_MS_NAME="deposit-v1"
    TELLER_MS_NAME="teller-v1"
    REPORT_MS_NAME="report-v1"
    CHEQUES_MS_NAME="cheques-v1"
    PAYROLL_MS_NAME="payroll-v1"
    GROUP_MS_NAME="group-v1"
    NOTIFICATIONS_MS_NAME="notification-v1"
}

function config-kubernetes-addresss {
    kubectl get services | awk '{print $1","$4}' | grep -v "NAME,EXTERNAL-IP" > cluster_addressess.txt
    while IFS="=" read -r LINE; do
        ip=$(echo "${LINE}" | awk -F',' '{print $2}')
        service=$(echo "${LINE}" | awk -F',' '{print $1}')
        if [[ ${#ip} -gt 0  ]]
        then
            case "$service" in
                '#'*) ;;
                "cassandra-cluster")    CASSANDRA_CONTACT_POINTS="$ip:9042" ;;
                "postgresdb-cluster")   POSTGRES_HOST="$ip" ;;
                "provisioner-service")   PROVISIONER_URL="http://$ip:2020/provisioner/v1" ;;
                "identity-ms")   IDENTITY_URL="http://$ip:2021/identity/v1" ;;
                "rhythm-service")   RHYTHM_URL="http://$ip:2022/rhythm/v1" ;;
                "office-ms") OFFICE_URL="http://$ip:2023/office/v1" ;;
                "customer-ms")   CUSTOMER_URL="http://$ip:2024/customer/v1" ;;
                "accounting-ms")   ACCOUNTING_URL="http://$ip:2025/accounting/v1" ;;
                "portfolio-ms")   PORTFOLIO_URL="http://$ip:2026/portfolio/v1" ;;
                "deposit-account-management-ms")   DEPOSIT_URL="http://$ip:2027/deposit/v1" ;;
                "teller-ms")   TELLER_URL="http://$ip:2028/teller/v1" ;;
                "reporting-ms")   REPORT_URL="http://$ip:2029/report/v1" ;;
                "cheques-ms")   CHEQUES_URL="http://$ip:2030/cheques/v1" ;;
                "payroll-ms")   PAYROLL_URL="http://$ip:2031/payroll/v1" ;;
                "group-ms")   GROUP_URL="http://$ip:2032/group/v1" ;;
                "notifications-ms")   NOTIFICATIONS_URL="http://$ip:2033/notification/v1" ;;
            esac
        elif [[ ${service} != "kubernetes"  ]]
        then
            echo "$service ip has not been conigured"
            exit 1
        fi
    done < "cluster_addressess.txt"

    if [[ "${CASSANDRA_CONTACT_POINTS}" == "UNKNOWN" ]]; then echo "Unknown CASSANDRA_CONTACT_POINTS"; exit 1; fi
    if [[ "${PROVISIONER_URL}" == "UNKNOWN" ]]; then echo "Unknown PROVISIONER_URL"; exit 1; fi
    if [[ "${IDENTITY_URL}" == "UNKNOWN" ]]; then echo "Unknown IDENTITY_URL"; exit 1; fi
    if [[ "${RHYTHM_URL}" == "UNKNOWN" ]]; then echo "Unknown RHYTHM_URL"; exit 1; fi
    if [[ "${OFFICE_URL}" == "UNKNOWN" ]]; then echo "Unknown OFFICE_URL"; exit 1; fi
    if [[ "${CUSTOMER_URL}" == "UNKNOWN" ]]; then echo "Unknown CUSTOMER_URL"; exit 1; fi
    if [[ "${ACCOUNTING_URL}" == "UNKNOWN" ]]; then echo "Unknown ACCOUNTING_URL"; exit 1; fi
    if [[ "${PORTFOLIO_URL}" == "UNKNOWN" ]]; then echo "Unknown PORTFOLIO_URL"; exit 1; fi
    if [[ "${DEPOSIT_URL}" == "UNKNOWN" ]]; then echo "Unknown DEPOSIT_URL"; exit 1; fi
    if [[ "${TELLER_URL}" == "UNKNOWN" ]]; then echo "Unknown TELLER_URL"; exit 1; fi
    if [[ "${REPORT_URL}" == "UNKNOWN" ]]; then echo "Unknown REPORT_URL"; exit 1; fi
    if [[ "${CHEQUES_URL}" == "UNKNOWN" ]]; then echo "Unknown CHEQUES_URL"; exit 1; fi
    if [[ "${PAYROLL_URL}" == "UNKNOWN" ]]; then echo "Unknown PAYROLL_URL"; exit 1; fi
    if [[ "${GROUP_URL}" == "UNKNOWN" ]]; then echo "Unknown GROUP_URL"; exit 1; fi
    if [[ "${NOTIFICATIONS_URL}" == "UNKNOWN" ]]; then echo "Unknown NOTIFICATIONS_URL"; exit 1; fi

    echo "Successfully configured kubernetes ip addresses"
}

function auto-seshat {
    TOKEN=$( curl -s -X POST -H "Content-Type: application/json" \
        "$PROVISIONER_URL"'/auth/token?grant_type=password&client_id=service-runner&username=wepemnefret&password=oS/0IiAME/2unkN1momDrhAdNKOhGykYFH/mJN20' \
         | jq --raw-output '.token' )

    if [[ "${TOKEN}" == "" ]]; then
        echo "ERROR: TOKEN is null"
        exit 1
    else
        echo "auto-seshat OK"
        echo "TOKEN=${TOKEN}"
        sleep 10
    fi
}

function login {
    local tenant="$1"
    local username="$2"
    local password="$3"

    ACCESS_TOKEN=$( curl -s -X POST -H "Content-Type: application/json" -H "User: guest" -H "X-Tenant-Identifier: $tenant" \
       "${IDENTITY_URL}/token?grant_type=password&username=${username}&password=${password}" \
        | jq --raw-output '.accessToken' )

    if [[ "${ACCESS_TOKEN}" == "" || "${ACCESS_TOKEN}" == "null" ]]; then
        echo "ERROR: login failed, ACCESS_TOKEN is null"
        exit 1
    else
        echo "login as ${username} with password ${password}"
        sleep 5
    fi
}

function create-application {
    local name="$1"
    local description="$2"
    local vendor="$3"
    local homepage="$4"

    curl -X POST -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" \
    --data '{ "name": "'"$name"'", "description": "'"$description"'", "vendor": "'"$vendor"'", "homepage": "'"$homepage"'" }' \
     ${PROVISIONER_URL}/applications
    echo "Created microservice: $name"
}

function get-application {
    echo ""
    echo "Microservices: "
    curl -s -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" ${PROVISIONER_URL}/applications | jq '.'
}

function delete-application {
    local service_name="$1"

    curl -X delete -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" ${PROVISIONER_URL}/applications/${service_name}
    echo "Deleted microservice: $name"
}

function create-tenant {
    local identifier="$1"
    local name="$2"
    local description="$3"
    local database_name="$4"

    curl -X POST -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" \
    --data '{
	"identifier": "'$identifier'",
	"name": "'$name'",
	"description": "'"$description"'",
	"cassandraConnectionInfo": {
		"clusterName": "'$CASSANDRA_CLUSTER_NAME'",
		"contactPoints": "'$CASSANDRA_CONTACT_POINTS'",
		"keyspace": "'$database_name'",
		"replicationType": "'$CASSANDRA_REPLICATION_TYPE'",
		"replicas": "'$CASSANDRA_REPLICAS'"
	},
	"databaseConnectionInfo": {
		"driverClass": "'$POSTGRES_DRIVER_CLASS'",
		"databaseName": "'$database_name'",
		"host": "'$POSTGRES_HOST'",
		"port": "'$POSTGRESQL_PORT'",
		"user": "'$POSTGRESQL_USER'",
		"password": "'$POSTGRES_PWD'"
	}}' \
    ${PROVISIONER_URL}/tenants
    echo "Created tenant: $database_name"
}

function get-tenants {
    echo ""
    echo "Tenants: "
    curl -s -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" ${PROVISIONER_URL}/tenants | jq '.'
}

function assign-identity-ms {
    local tenant="$1"

    ADMIN_PASSWORD=$( curl -s -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" -H "X-Tenant-Identifier: $tenant" \
	--data '{ "name": "'"$IDENTITY_MS_NAME"'" }' \
	${PROVISIONER_URL}/tenants/${tenant}/identityservice | jq --raw-output '.adminPassword')

    echo "Assigned identity microservice for tenant $tenant"
}

function get-tenant-services {
    local tenant="$1"

    echo ""
    echo "$tenant services: "
    curl -s -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" -H "X-Tenant-Identifier: $tenant" ${PROVISIONER_URL}/tenants/$tenant/applications | jq '.'
}

function create-scheduler-role {
    local tenant="$1"

    curl -H "Content-Type: application/json" -H "User: antony" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
                "identifier": "scheduler",
                "permissions": [
                        {
                                "permittableEndpointGroupIdentifier": "identity__v1__app_self",
                                "allowedOperations": ["CHANGE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "portfolio__v1__khepri",
                                "allowedOperations": ["CHANGE"]
                        }
                ]
        }' \
        ${IDENTITY_URL}/roles
    echo "Created scheduler role"
}

function create-org-admin-role {
    local tenant="$1"

    curl -H "Content-Type: application/json" -H "User: antony" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
                "identifier": "orgadmin",
                "permissions": [
                        {
                                "permittableEndpointGroupIdentifier": "office__v1__employees",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "office__v1__offices",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "identity__v1__users",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "identity__v1__roles",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "identity__v1__self",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "accounting__v1__ledger",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        },
                        {
                                "permittableEndpointGroupIdentifier": "accounting__v1__account",
                                "allowedOperations": ["READ", "CHANGE", "DELETE"]
                        }
                ]
        }' \
        ${IDENTITY_URL}/roles
    echo "Created organisation administrator role"
}

function create-user {
    local tenant="$1"
    local user="$2"
    local user_identifier="$3"
    local password="$4"
    local role="$5"

    curl -s -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
                "identifier": "'"$user_identifier"'",
                "password": "'"$password"'",
                "role": "'"$role"'"
        }' \
        ${IDENTITY_URL}/users | jq '.'
    echo "Created user: $user_identifier"
}

function get-users {
    local tenant="$1"
    local user="$2"

    echo ""
    echo "Users: "
    curl -s -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" ${IDENTITY_URL}/users | jq '.'
}

function update-password {
    local tenant="$1"
    local user="$2"
    local password="$3"

    curl -s -X PUT -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
                "password": "'"$password"'"
        }' \
        ${IDENTITY_URL}/users/${user}/password | jq '.'
    echo "Updated $user password"
}

function provision-app {
    local tenant="$1"
    local service="$2"

    curl -s -X PUT -H "Content-Type: application/json" -H "User: wepemnefret" -H "Authorization: ${TOKEN}" \
	--data '[{ "name": "'"$service"'" }]' \
	${PROVISIONER_URL}/tenants/${tenant}/applications | jq '.'
    echo "Provisioned microservice, $service for tenant, $tenant"
}

function set-application-permission-enabled-for-user {
    local tenant="$1"
    local service="$2"
    local permission="$3"
    local user="$4"

    curl -s -X PUT -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
	--data 'true' \
	${IDENTITY_URL}/applications/${service}/permissions/${permission}/users/${user}/enabled | jq '.'
    echo "Enabled permission, $permission for service $service"
}

function create_chart_of_accounts {
    local ledger_file="ledgers.csv"
    local accounts_file="accounts.csv"
    local tenant="$1"
    local user="$2"

    create_ledgers "$ledger_file" "$tenant" "$user"
    create_accounts "$accounts_file" "$tenant" "$user"
}

function create_accounts {
    local accounts_file="$1"
    local tenant="$2"
    local user="$3"

    echo ""
    echo "Creating accounts..."
    while IFS="," read -r parent_id id name; do
        if [ "$parent_id" != "parentIdentifier" ]; then
            local ledger_arr
            local ledger_type

            IFS=',' read -ra ledger_arr <<< $( grep $parent_id -m 1 ledgers.csv )
            ledger_type=${ledger_arr[3]}
            create_account "$tenant" "$user" "$parent_id" "$id" "$name" "$ledger_type"
        fi
    done < "$accounts_file"
}

function create_ledgers {
    local ledger_file="$1"
    local tenant="$2"
    local user="$3"

    echo ""
    echo "Creating ledgers..."
    while IFS="," read -r parent_id id description ledger_type show; do
        if [ "$parent_id" != "parentIdentifier" ]; then
            if [ -z "$parent_id" ]; then
                create_ledger "$tenant" "$user" "$id" "$description" "$ledger_type" "$show"
                sleep 5s
            else
                update_ledger "$tenant" "$user" "$id" "$parent_id" "$description" "$ledger_type" "$show"
            fi
        fi

    done < "$ledger_file"
}

function create_account {
    local tenant="$1"
    local user="$2"
    local parent_id="$3"
    local id="$4"
    local name="$5"
    local type="$6"

    curl -X POST -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
            "type": "'"$type"'",
            "identifier": "'"$id"'",
            "name": '"$name"',
            "name": '"$name"',
            "holders": [],
            "signatureAuthorities": [],
            "balance": 0.0,
            "ledger": "'"$parent_id"'"
        }' \
        ${ACCOUNTING_URL}/accounts
    echo ""
    echo "Created account $id : $name"
}

function create_ledger {
    local tenant="$1"
    local user="$2"
    local id="$3"
    local description="$4"
    local ledger_type="$5"
    local show="$6"

    curl -X POST -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
            "type": "'"$ledger_type"'",
            "identifier": "'"$id"'",
            "name": "'"$id"'",
            "description": '"$description"',
            "showAccountsInChart": '$show'
        }' \
        ${ACCOUNTING_URL}/ledgers
    echo ""
    echo "Created ledge account $id : $description"
}

function update_ledger {
    local tenant="$1"
    local user="$2"
    local id="$3"
    local parent_id="$4"
    local description="$5"
    local ledger_type="$6"
    local show="$7"

    curl -X POST -H "Content-Type: application/json" -H "User: $user" -H "Authorization: ${ACCESS_TOKEN}" -H "X-Tenant-Identifier: $tenant" \
        --data '{
            "type": "'"$ledger_type"'",
            "identifier": "'"$id"'",
            "name": "'"$id"'",
            "description": '"$description"',
            "parentLedgerIdentifier": "'"$parent_id"'",
            "showAccountsInChart": '$show'
        }' \
        ${ACCOUNTING_URL}/ledgers/${parent_id}
    echo "Add ledge account $id : $description to $parent_id"
}

init-variables
if [[ "$1" == "--deploy-on-kubernetes" ]]; then
    config-kubernetes-addresss
    TENANT=$2
elif [[ "$2" == "--deploy-on-kubernetes" ]]; then
    config-kubernetes-addresss
    TENANT=$1
else
    TENANT=$1
fi

auto-seshat
create-application "$IDENTITY_MS_NAME" "" "$MS_VENDOR" "$IDENTITY_URL"
create-application "$RHYTHM_MS_NAME" "" "$MS_VENDOR" "$RHYTHM_URL"
create-application "$OFFICE_MS_NAME" "" "$MS_VENDOR" "$OFFICE_URL"
create-application "$CUSTOMER_MS_NAME" "" "$MS_VENDOR" "$CUSTOMER_URL"
create-application "$ACCOUNTING_MS_NAME" "" "$MS_VENDOR" "$ACCOUNTING_URL"
create-application "$PORTFOLIO_MS_NAME" "" "$MS_VENDOR" "$PORTFOLIO_URL"
create-application "$DEPOSIT_MS_NAME" "" "$MS_VENDOR" "$DEPOSIT_URL"
create-application "$TELLER_MS_NAME" "" "$MS_VENDOR" "$TELLER_URL"
create-application "$REPORT_MS_NAME" "" "$MS_VENDOR" "$REPORT_URL"
create-application "$CHEQUES_MS_NAME" "" "$MS_VENDOR" "$CHEQUES_URL"
create-application "$PAYROLL_MS_NAME" "" "$MS_VENDOR" "$PAYROLL_URL"
create-application "$GROUP_MS_NAME" "" "$MS_VENDOR" "$GROUP_URL"
create-application "$NOTIFICATIONS_MS_NAME" "" "$MS_VENDOR" "$NOTIFICATIONS_URL"

# Set tenant identifier
create-tenant ${TENANT} "${TENANT}" "All in one Demo Server" ${TENANT}

# Sets ADMIN_PASSWORD
assign-identity-ms ${TENANT}
echo "$ADMIN_PASSWORD" > admin_pass.txt

login ${TENANT} "antony" $ADMIN_PASSWORD
provision-app ${TENANT} $RHYTHM_MS_NAME
provision-app ${TENANT} $OFFICE_MS_NAME
provision-app ${TENANT} $CUSTOMER_MS_NAME
create-org-admin-role ${TENANT}
# Base64Encode(init1@l23) = aW5pdDFAbDIz
create-user ${TENANT} "antony" "operator" "aW5pdDFAbDIz" "orgadmin"
login ${TENANT} "operator" "aW5pdDFAbDIz"
update-password ${TENANT} "operator" "aW5pdDFAbDIz"
login ${TENANT} "antony" $ADMIN_PASSWORD
create-scheduler-role ${TENANT}
# Base64Encode(p4ssw0rd) = cDRzc3cwcmQ=
create-user ${TENANT} "antony" "imhotep" "cDRzc3cwcmQ=" "scheduler"
login ${TENANT} "imhotep" "cDRzc3cwcmQ="
update-password ${TENANT} "imhotep" "cDRzc3cwcmQ="
login ${TENANT} "imhotep" "cDRzc3cwcmQ="
echo "Waiting for Rhythm to provision"
sleep 15s
set-application-permission-enabled-for-user ${TENANT} $RHYTHM_MS_NAME "identity__v1__app_self" "imhotep"
provision-app ${TENANT} $ACCOUNTING_MS_NAME
provision-app ${TENANT} $PORTFOLIO_MS_NAME
echo "Waiting for Portfolio to provision."
sleep 45s
set-application-permission-enabled-for-user ${TENANT} $RHYTHM_MS_NAME "portfolio__v1__khepri" "imhotep"
provision-app ${TENANT} $DEPOSIT_MS_NAME
provision-app ${TENANT} $TELLER_MS_NAME
provision-app ${TENANT} $REPORT_MS_NAME
provision-app ${TENANT} $CHEQUES_MS_NAME
provision-app ${TENANT} $PAYROLL_MS_NAME
provision-app ${TENANT} $GROUP_MS_NAME
provision-app ${TENANT} $NOTIFICATIONS_MS_NAME
login ${TENANT} "operator" "aW5pdDFAbDIz"
create_chart_of_accounts ${TENANT} "operator"
echo "COMPLETED PROVISIONING PROCESS."
