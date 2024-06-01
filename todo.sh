#!/bin/bash

# Path for the tasks file
TASKS_PATH="$HOME/Documents/Projects/todo.txt"

# Validation of the date as date -d is not supported on macOS
validate_date() {
    local date="$1"

    # Checks if its not in the nn-nn-nnnn format
    if ! [[ "$date" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
        return 1
    fi

    # Convert dd-mm-yyyy to yyyy-mm-dd and try to parte the date using the date command
    local reformatted_date=$(echo "$date" | awk -F- '{print $3"-"$2"-"$1}')
    if ! date -jf "%Y-%m-%d" "$reformatted_date" >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

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

update_task() {
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

    # Taking and cheking the update options
    while true; do
        echo "What do you want to update? (1. Title, 2. Description, 3. Location, 4. Due Date, 5. Completion)"
        read -r choice
        if [[ "$choice" =~ ^[1-5]$ ]]; then
            break 
        else
            echo "Invalid choice. Please choose a number between 1 and 5" >&2
        fi
    done

    # Saving the new value
    echo "Enter the new value: "
    read -r new_value

    # Validating the input for specific fields
    case $choice in
        4)
            # Validate the new due date
            while true; do
                if  validate_date "$new_value"; then
                    break
                else 
                    echo "Enter the due date of the task (DD-MM-YYYY): "
                    read -r new_value
                fi  
            done
            ;;
        5)
            # Validate the completion status (default not completed)
            if [ "$new_value" != "completed" ]; then
                new_value="notcompleted"
            fi
            ;;
    esac

    # Update the specified field
    awk -v task_id="$task_id" -v choice="$choice" -v new_value="$new_value" 'BEGIN {FS=OFS=";"} $1 == task_id {
        if (choice == 1) $2 = new_value;
        else if (choice == 2) $3 = new_value;
        else if (choice == 3) $4 = new_value;
        else if (choice == 4) $5 = new_value;
        else if (choice == 5) $6 = new_value;
    } 1' "$TASKS_PATH" > temp && mv temp "$TASKS_PATH" && echo "Task updated successfully."
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

task_info() {
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

    # Utilisation de awk pour rechercher la tâche spécifique et l'afficher
    awk -v task_id="$task_id" -F ';' 'BEGIN {found=0}
        $1 == task_id {
            print "Task ID: " $1
            print "Title: " $2
            print "Description: " $3
            print "Location: " $4
            print "Due Date: " $5
            print "Completion: " $6
            found=1
 exit
        }
        END {
            if(found==0){
                print "Task with ID " task_id " not found"
            }
        }
    ' "$TASKS_PATH"
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

# Searching the task by title
search_task() {
    # Making sure the title is not an empty string
    local search_title="$1"
    while true; do
        if [ -z "$search_title" ]; then
            echo "Error: Title cannot be empty. Please enter a title." >&2
            read -r search_title
        else
            break
        fi
    done

    # Recherche de toutes les tâches ayant le même titre
    matching_tasks=$(awk -v title="$search_title" 'BEGIN {FS=OFS=";"}{if($2 == title) print $0}' "$TASKS_PATH")

    # Affichage des tâches correspondantes
    if [ -n "$matching_tasks" ]; then
        echo "Tasks with title '$search_title':"
        echo "$matching_tasks" | column -s ';' -t
    else
        echo "No tasks found with title '$search_title'."
    fi
}

show_help() {
    echo "Usage: $0 <command>"
    echo "Commands:"
    echo "  create      Create a new task"
    echo "  update      Update an existing task (by ID)"
    echo "  delete      Delete a task (by ID)"
    echo "  info        Show information of a task (by ID)"
    echo "  list        List tasks of a given day (second argument of the command) in two sections: completed and uncompleted"
    echo "  search      Search a task by its title"
}


# Vérifier si l'argument --help est passé
if [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Si aucun argument n'est passé, afficher les tâches du jour actuel
if [ $# -eq 0 ]; then
    current_date=$(date +'%d-%m-%Y')
    list_tasks "$current_date"
    exit 0
fi

# Vérifier le premier argument pour déterminer quelle fonctionnalité exécuter
case "$1" in
    -c)
        create_task $2 $3
        ;;
    -u)
        update_task $2
        ;;
    -d)
        delete_task $2
        ;;
    -i)
        task_info $2
        ;;
    -l)
        list_tasks $2
        ;;
    -a)
        list_all
        ;;
    -s)
        search_task $2
        ;;
    *)
        echo "Error: Unknown command '$1'. Use --help for usage."
        exit 1
        ;;
esac
