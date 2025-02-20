#!/bin/bash

# Path for the tasks file
TASKS_PATH="$HOME/.todo_list"



create_task() {
    # Verify if task is not created  
    if [ ! -e "$TASKS_PATH" ]; then
        touch "$TASKS_PATH"
    fi

    # Title required
    local title=$1
    while true; do
        if [ -z "$title" ]; then
            echo "Error: Title cannot be empty. Please enter a title.">&2
            read -r title
        else
            break
        fi
    done

    # Due date required
    local due_date=$2
    while true; do
        if [ -z "$due_date" ]; then
            echo "Error : Due Date cannot be empty . Please enter a due date of the task (DD-MM-YYYY): ">&2
            read -r due_date
        # Validate due date format
        elif ! validate_date "$due_date"; then
            echo "Error: Invalid date format. Please enter the date in DD-MM-YYYY format." >&2
            read -r due_date
        else
            break
        fi
    done

    # Optional description
    echo "Enter the description of the task: "
    read -r description

    # Optional location
    echo "Enter the location of the task: "
    read -r location

    # Optional completion (default no)
    echo "Is the task completed? (yes/no): "
    read -r completion
    if [ "$completion" == "yes" ]; then
        completion="completed"
    else
        completion="notcompleted"
    fi

    # Generate task ID
    task_id=0
    if [ -s "$TASKS_PATH" ]; then
        highest_id=0
        while IFS=';' read -r id _; do
            if (( id > highest_id )); then
                highest_id=$id
            fi
        done < "$TASKS_PATH"
        task_id=$((highest_id + 1))
    fi

    # Appending the task to the task file
    echo "$task_id;$title;$description;$location;$due_date;$completion" >> "$TASKS_PATH" && echo "Task added successfully."
}



    

delete_task() {
    local task_id=$1
    # Taking and cheking the validity of the given id
    task_id_exists=false
    while ! $task_id_exists; do
        while IFS=';' read -r id _; do
            if [ "$id" = "$task_id" ]; then
                task_id_exists=true
                break
            fi
        done < "$TASKS_PATH"
        if ! $task_id_exists; then
            echo "Error: ID not found or invalid. Please enter the ID:" >&2
            read -r task_id
        fi
    done

    # Delete the specified task
    awk -v task_id="$task_id" 'BEGIN {FS=OFS="    "} $1 != task_id {print $0}' "$TASKS_PATH" > temp && mv temp "$TASKS_PATH" && echo "Task deleted successfully."
}



list_tasks() {

    local cdate="$1"

    # Vérification de la validité du format de la date
    while true; do 
        if ! validate_date "$cdate"; then
            echo "Invalid date format. Please enter the date in DD-MM-YYYY format." >&2
            read -r cdate
        else 
            break
        fi
    done

    # Séparer les tâches complétées et non complétées
    completed_tasks=$(awk -v date="$cdate" 'BEGIN {FS=OFS=";"}{if($5 == date && $6 == "completed") print $0}' "$TASKS_PATH")
    notcompleted_tasks=$(awk -v date="$cdate" 'BEGIN {FS=OFS=";"}{if($5 == date && $6 != "completed") print $0}' "$TASKS_PATH")

    # Afficher les tâches complétées
    if [ -n "$completed_tasks" ]; then
        echo "----------------------------------------------"
        echo "$(echo "$completed_tasks" | wc -l | awk '{$1=$1};1') Completed tasks for $cdate:"
        echo "$completed_tasks" | column -s ';' -t
    else
        echo "----------------------------------------------"
        echo "No completed tasks for $cdate."
    fi

    # Afficher les tâches non complétées
    if [ -n "$notcompleted_tasks" ]; then
        echo "----------------------------------------------"
        echo "$(echo "$notcompleted_tasks" | wc -l | awk '{$1=$1};1') Not completed tasks for $cdate:"
        echo "$notcompleted_tasks" | column -s ';' -t
    else
        echo "----------------------------------------------"
        echo "No not completed tasks for $cdate."
    fi
}

list_all() {

    # Séparer les tâches complétées et non complétées
    tasks=$(awk 'BEGIN {FS=OFS=";"}{if($6 == "completed") print $0}' "$TASKS_PATH")
    notcompleted_tasks=$(awk 'BEGIN {FS=OFS=";"}{if($6 != "completed") print $0}' "$TASKS_PATH")

    # Afficher les tâches complétées
    if [ -n "$completed_tasks" ]; then
        echo "----------------------------------------------"
        echo "$(echo "$completed_tasks" | wc -l | awk '{$1=$1};1') Completed tasks:"
        echo "$completed_tasks" | column -s ';' -t
    else
        echo "----------------------------------------------"
        echo "No completed tasks."
    fi

    # Afficher les tâches non complétées
    if [ -n "$notcompleted_tasks" ]; then
        echo "----------------------------------------------"
        echo "$(echo "$notcompleted_tasks" | wc -l | awk '{$1=$1};1') Not completed tasks:"
        echo "$notcompleted_tasks" | column -s ';' -t
    else
        echo "----------------------------------------------"
        echo "No not completed tasks."
    fi
}







todo() {
    # Si aucun argument n'est passé, afficher message d erreur
    if [ $# -eq 0 ]; then
        echo "La commande ’todo ’ s ’ ex´ecute avec ’ todo ( add | done | list ) ( arguments ) ’"
        
        exit 0
    fi

    # Vérifier le premier argument pour déterminer quelle fonctionnalité exécuter
    case "$1" in
        add)
            create_task $2 $3
            ;;
        
        done)
            delete_task $2
            ;;
    
        
        list)
            list_all
            ;;
        
        *)
            echo "La commande ’todo ’ s ’ ex´ecute avec ’ todo ( add | done | list ) ( arguments ) ’"
            exit 1
            ;;

    esac}
