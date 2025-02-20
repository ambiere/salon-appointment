#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --no-align -t -c"

echo -e "\n~~~~~ MY SALON ~~~~~"

ADD_CUSTOMER() {
	if [[ $# -ne 2 ]]; then
		echo "[args error] Failed to add new customer. Invalid customer info"
		exit 1
	fi
	local CUSTOMER_PHONE=$1
	local CUSTOMER_NAME=$2
	local CUSTOMER_ID=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME') ON CONFLICT DO NOTHING RETURNING customer_id")
	local CUSTOMER_ID=$(echo -e "$CUSTOMER_ID" | head -n 1 | sed -E 's/(^[0-9]+$)/\1/')
	echo "$CUSTOMER_ID"
}

ADD_APPOINTMENT() {
	if [[ $# -ne 4 ]]; then
		echo "[args error] Failed to add new appointment. Invalid appointment info"
		exit 1
	fi

	local CUSTOMER_ID=$1
	local SERVICE_ID=$2
	local SERVICE_TIME=$3
	local CUSTOMER_NAME=$4
	local SERVICE_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID")
	local INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID, '$SERVICE_TIME')")
	echo -e "\nI have put you down for a $SERVICE_SELECTED at $SERVICE_TIME, $CUSTOMER_NAME."

}

MAIN_MENU() {
	if [[ $1 ]]; then
		echo -e "\n$1"
	fi

	echo -e "\nWelcome to My Salon, how can I help you?"
	echo -e "\n1) cut\n2) color\n3) perm\n4) style\n5) trim"
	read SERVICE_ID_SELECTED

	if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
		MAIN_MENU "I could not find that service. What would you like today?"
	else
		SERVICE_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")

		if [[ -z $SERVICE_SELECTED ]]; then
			MAIN_MENU "I could not find that service. What would you like today?"
		else
			echo -e "\nWhat's your phone number?"
			read CUSTOMER_PHONE

			CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

			if [[ -z $CUSTOMER_ID ]]; then
				echo -e "\nI don't have a record for that phone number, what's your name?"
				read CUSTOMER_NAME

				CUSTOMER_ID=$(ADD_CUSTOMER $CUSTOMER_PHONE $CUSTOMER_NAME)
				echo -e "\nWhat time would you like your $SERVICE_SELECTED, $CUSTOMER_NAME?"
				read SERVICE_TIME

				if [[ -z $CUSTOMER_ID || $CUSTOMER_ID == "INSERT 0 0" ]]; then
					echo "Failed to add new customer. Phone number exist."
					exit 1
				fi

				ADD_APPOINTMENT $CUSTOMER_ID $SERVICE_ID_SELECTED $SERVICE_TIME $CUSTOMER_NAME
			else
				CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")

				echo -e "\nWhat time would you like your $SERVICE_SELECTED, $CUSTOMER_NAME?"
				read SERVICE_TIME

				ADD_APPOINTMENT $CUSTOMER_ID $SERVICE_ID_SELECTED $SERVICE_TIME $CUSTOMER_NAME
			fi
		fi
	fi
}

case $# in
0)
	MAIN_MENU
	;;
3)
	SERVICE_ID_SELECTED=$1
	CUSTOMER_PHONE=$2
	SERVICE_TIME=$3

	CUSTOMER_INFO=$($PSQL "SELECT customer_id, name FROM customers WHERE phone='$CUSTOMER_PHONE'")
	CUSTOMER_ID=$(echo "$CUSTOMER_INFO" | cut -d "|" -f 1)
	CUSTOMER_NAME=$(echo "$CUSTOMER_INFO" | cut -d "|" -f 2)

	if [[ -z $CUSTOMER_ID ]]; then
		echo -e "Customer with phone number $CUSTOMER_PHONE does not exist."
		exit 1
	fi

	ADD_APPOINTMENT $CUSTOMER_ID $SERVICE_ID_SELECTED $SERVICE_TIME $CUSTOMER_NAME
	;;
4)
	SERVICE_ID_SELECTED=$1
	CUSTOMER_PHONE=$2
	CUSTOMER_NAME=$3
	SERVICE_TIME=$4
	CUSTOMER_ID=$(ADD_CUSTOMER $CUSTOMER_PHONE $CUSTOMER_NAME)
	if [[ -z $CUSTOMER_ID || $CUSTOMER_ID == "INSERT 0 0" ]]; then
		echo -e "Failed to add new customer. Phone number exist."
		exit 1
	fi
	ADD_APPOINTMENT $CUSTOMER_ID $SERVICE_ID_SELECTED $SERVICE_TIME $CUSTOMER_NAME
	;;

*)
	MAIN_MENU "Invalid arguments:/"
	;;
esac
