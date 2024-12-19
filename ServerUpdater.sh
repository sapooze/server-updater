#!/bin/bash

echo ServerUpdater - Version 1.1.0 - by sapooze

# Load config from file
config_file="serverupdater-config.json"
if [[ -f "$config_file" ]]; then
    config=$(cat "$config_file")
    folders=$(echo "$config" | jq -c '.folders')
    server_jar_name=$(echo "$config" | jq -r '.server_jar_name')
    bungeecord_jar_name=$(echo "$config" | jq -r '.bungeecord_jar_name')
else
    echo "Config file not found. Creating a new one."
    folders='[]'
fi

# Function to save the configuration
save_config() {
    new_config=$(jq -n \
        --argjson folders "$folders" \
        --arg server_jar_name "$server_jar_name" \
        --arg bungeecord_jar_name "$bungeecord_jar_name" \
        '{folders: $folders, server_jar_name: $server_jar_name, bungeecord_jar_name: $bungeecord_jar_name}')
    echo "$new_config" > "$config_file"
    echo "Configuration saved to $config_file."
}

# Menu
while true; do
    echo "Please choose an option:"
    echo "1 - Update a Server"
    echo "2 - Update a Bungeecord Server"
    echo "3 - Server Settings"
    echo "4 - Change the Server Jar Name"
    echo "5 - Change the Bungeecord Jar Name"
    echo "6 - Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            # Check if at least one server exists
            if [[ $(echo "$folders" | jq length) -eq 0 ]]; then
                echo "No server folders exist. Please add a server folder first."
                continue
            fi

            # Update a Server
            read -p "Enter the Minecraft version: " mc

            # Fetch the latest 5 build versions for the selected Minecraft version
            latest_builds=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/$mc" | jq -r '.builds[:5] | .[]')

            # Prompt for user input
            read -p "Enter the build version (or type 'latest' for the latest build): " build

            if [[ $build == "latest" ]]; then
                # Fetch the latest build version for the selected Minecraft version
                latest_build=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/$mc" | jq -r '.builds[-1]')
                echo "Latest build version for $mc: $latest_build"
                build=$latest_build
            fi

            # List available servers
            echo "Available servers:"
            available_servers=$(echo "$folders" | jq -r '.[].name')
            echo "$available_servers"

            # Prompt for user input
            read -p "Which servers do you want to update? (comma-separated list or 'all'): " selected_servers

            # Check if server jar name is set in the config file
            if [[ -z "$server_jar_name" || "$server_jar_name" == "null" ]]; then
                read -p "Name of the Server Jar? " server_jar_name
            fi

            read -p "This will delete the old $server_jar_name! Are you sure you want to execute the script? (y/n): " confirm

            if [[ $confirm == "y" || $confirm == "Y" ]]; then
                echo "Executing the script..."

                # Download the JAR file once
                url="https://api.papermc.io/v2/projects/paper/versions/$mc/builds/$build/downloads/paper-$mc-$build.jar"
                wget -O "$server_jar_name" "$url"

                # Determine the folders based on the server selection
                folders_to_update=()
                if [[ $selected_servers == "all" ]]; then
                    folders_to_update+=($(echo "$folders" | jq -r '.[].path'))
                else
                    IFS=',' read -ra server_array <<< "$selected_servers"
                    for server_name in "${server_array[@]}"; do
                        folders_to_update+=($(echo "$folders" | jq -r --arg name "$server_name" '.[] | select(.name == $name) | .path'))
                    done
                fi

                # Update the server jar in each folder
                for folder in "${folders_to_update[@]}"; do
                    # Delete the existing server jar file
                    if [[ -f "$folder/$server_jar_name" ]]; then
                        rm "$folder/$server_jar_name"
                    fi

                    # Copy the downloaded file to the server folder
                    cp "$server_jar_name" "$folder/$server_jar_name"

                    echo "Server in $folder updated successfully!"
                done

                # Clean up the downloaded JAR file
                rm "$server_jar_name"

            else
                echo "Script execution canceled."
            fi

            ;;
        2)
            # Check if at least one server exists
            if [[ $(echo "$folders" | jq length) -eq 0 ]]; then
                echo "No server folders exist. Please add a server folder first."
                continue
            fi

            # Update a Bungeecord Server
            # List available servers
            echo "Available servers:"
            available_servers=$(echo "$folders" | jq -r '.[].name')
            echo "$available_servers"

            # Prompt for user input
            read -p "Which servers do you want to update? (comma-separated list or 'all'): " selected_servers

            # Check if bungeecord jar name is set in the config file
            if [[ -z "$bungeecord_jar_name" || "$bungeecord_jar_name" == "null" ]]; then
                read -p "Name of the Bungeecord Jar? " bungeecord_jar_name
            fi

            read -p "This will delete the old $bungeecord_jar_name! Are you sure you want to execute the script? (y/n): " confirm

            if [[ $confirm == "y" || $confirm == "Y" ]]; then
                echo "Executing the script..."

                # Download the JAR file once
                url="https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar"
                wget -O "$bungeecord_jar_name" "$url"

                # Determine the folders based on the server selection
                folders_to_update=()
                if [[ $selected_servers == "all" ]]; then
                    folders_to_update+=($(echo "$folders" | jq -r '.[].path'))
                else
                    IFS=',' read -ra server_array <<< "$selected_servers"
                    for server_name in "${server_array[@]}"; do
                        folders_to_update+=($(echo "$folders" | jq -r --arg name "$server_name" '.[] | select(.name == $name) | .path'))
                    done
                fi

                # Update the bungeecord jar in each folder
                for folder in "${folders_to_update[@]}"; do
                    # Delete the existing bungeecord jar file
                    if [[ -f "$folder/$bungeecord_jar_name" ]]; then
                        rm "$folder/$bungeecord_jar_name"
                    fi

                    # Copy the downloaded file to the server folder
                    cp "$bungeecord_jar_name" "$folder/$bungeecord_jar_name"

                    echo "Bungeecord server in $folder updated successfully!"
                done

                # Clean up the downloaded JAR file
                rm "$bungeecord_jar_name"

            else
                echo "Script execution canceled."
            fi

            ;;
        3)
            # Server Settings Menu
            while true; do
                echo "Server Settings:"
                echo "1 - Add a Server Folder"
                echo "2 - List Server Folders"
                echo "3 - Change a Server Name"
                echo "4 - Change a Server Folder"
                echo "5 - Delete Server Folder"
                echo "6 - Back to the Menu"
                read -p "Enter your choice: " server_choice

                case $server_choice in
                    1)
                        # Add a Server Folder
                        read -p "Enter the name of the new server folder (or type 'cancel' to go back): " new_server_name
                        if [[ $new_server_name == "cancel" ]]; then
                            continue
                        fi
                        read -p "Enter the path of the new server folder: " new_server_path
                        folders=$(echo "$folders" | jq --arg name "$new_server_name" --arg path "$new_server_path" '. += [{"name": $name, "path": $path}]')
                        save_config
                        echo "Server folder added successfully."
                        ;;
                    2)
                        # List Server Folders
                        echo "Available servers:"
                        available_servers=$(echo "$folders" | jq -r '.[].name')
                        echo "$available_servers"
                        ;;
                    3)
                        # Change a Server Name
                        echo "Available servers:"
                        available_servers=$(echo "$folders" | jq -r '.[].name')
                        echo "$available_servers"
                        read -p "Enter the name of the server to change (or type 'cancel' to go back): " old_server_name
                        if [[ $old_server_name == "cancel" ]]; then
                            continue
                        fi
                        read -p "Enter the new name for the server: " new_server_name
                        folders=$(echo "$folders" | jq --arg old_name "$old_server_name" --arg new_name "$new_server_name" 'map(if .name == $old_name then .name = $new_name else . end)')
                        save_config
                        echo "Server name changed successfully."
                        ;;
                    4)
                        # Change a Server Folder
                        echo "Available servers:"
                        available_servers=$(echo "$folders" | jq -r '.[].name')
                        echo "$available_servers"
                        read -p "Enter the name of the server to change the folder (or type 'cancel' to go back): " server_name
                        if [[ $server_name == "cancel" ]]; then
                            continue
                        fi
                        read -p "Enter the new path for the server folder: " new_server_path
                        folders=$(echo "$folders" | jq --arg name "$server_name" --arg path "$new_server_path" 'map(if .name == $name then .path = $path else . end)')
                        save_config
                        echo "Server folder changed successfully."
                        ;;
                    5)
                        # Delete a Server Folder
                        echo "Available servers:"
                        available_servers=$(echo "$folders" | jq -r '.[].name')
                        echo "$available_servers"
                        read -p "Enter the name of the server folder to delete (or type 'cancel' to go back): " delete_server_name
                        if [[ $delete_server_name == "cancel" ]]; then
                            continue
                        fi
                        folders=$(echo "$folders" | jq --arg name "$delete_server_name" 'del(.[] | select(.name == $name))')
                        save_config
                        echo "Server folder deleted successfully."
                        ;;
                    6)
                        # Back to the Menu
                        break
                        ;;
                    *)
                        echo "Invalid option. Please try again."
                        ;;
                esac
            done
            ;;
        4)
            # Change the Server Jar Name
            read -p "Enter the new server jar name (or type 'cancel' to go back): " new_server_jar_name
            if [[ $new_server_jar_name == "cancel" ]]; then
                continue
            fi
            server_jar_name=$new_server_jar_name
            save_config
            echo "Server jar name changed successfully."
            ;;
        5)
            # Change the Bungeecord Jar Name
            read -p "Enter the new bungeecord jar name (or type 'cancel' to go back): " new_bungeecord_jar_name
            if [[ $new_bungeecord_jar_name == "cancel" ]]; then
                continue
            fi
            bungeecord_jar_name=$new_bungeecord_jar_name
            save_config
            echo "Bungeecord jar name changed successfully."
            ;;
        6)
            # Exit
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
