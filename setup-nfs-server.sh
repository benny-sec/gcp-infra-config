#!/usr/bin/env bash
# nfs server installation (tested on Ubuntu 18.04)

NFS_ROOT="/srv/nfs4"
NFS_v3_ROOT="/srv/nfs3"

ATLASSIAN_SHARED_DIR="/var/atlassian/shared_home"
JIRA_SHARED_DIR="${ATLASSIAN_SHARED_DIR}/jira"
CONFLUENCE_SHARED_DIR="${ATLASSIAN_SHARED_DIR}/confluence"
BITBUCKET_SHARED_DIR="${ATLASSIAN_SHARED_DIR}/bitbucket"

NFS_PATH_FOR_ATLASSIAN_SHARED_DIR="/srv/nfs4/atlas_shared_home"
NFS_PATH_FOR_JIRA_SHARED_DIR="${NFS_PATH_FOR_ATLASSIAN_SHARED_DIR}/jira"
NFS_PATH_FOR_CONFLUENCE_SHARED_DIR="${NFS_PATH_FOR_ATLASSIAN_SHARED_DIR}/confluence"


NFS_PATH_FOR_BITBUCKET_SHARED_DIR="${NFS_v3_ROOT}/atlas_shared_home/bitbucket"




echo_color() {
    case $1 in
        "red")
            echo "`tput setaf 1``tput bold`$2`tput sgr0`"
            ;;
        *)
            echo "`tput setaf 4``tput bold`$1`tput sgr0`"
            ;;
    esac
}

get_args() {
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
            --help|-h)
                print_usage
                exit 0
                ;;
            *)    # unknown option
                shift # past argument
                ;;
        esac
    done
}

install_nfs_server() {
    # 1. Install the NFS server 
    sudo apt update && sudo apt -y install nfs-kernel-server

    # 2. Create the necessary directories
    #      a.  global root directory for the nfs server
    #      b.  mount points for bind mounting the atlassian shared dir to the nfs export dir.
    #          the exported directories needs to be relative to the nfs root directory, hence the bind mount 
    #      c.  atlassian home directory along with independent shared dir for each of the product variants 
    sudo mkdir -p ${ATLASSIAN_SHARED_DIR} ${JIRA_SHARED_DIR} ${CONFLUENCE_SHARED_DIR} ${BITBUCKET_SHARED_DIR}
    sudo mkdir -p ${NFS_PATH_FOR_ATLASSIAN_SHARED_DIR} ${NFS_PATH_FOR_JIRA_SHARED_DIR} ${NFS_PATH_FOR_CONFLUENCE_SHARED_DIR} ${NFS_PATH_FOR_BITBUCKET_SHARED_DIR}
    sudo chown -R blackhawk:blackhawk ${ATLASSIAN_SHARED_DIR}

    # 2. Bind mount the atlassian home directory to the nfs share mount points
    echo "${ATLASSIAN_SHARED_DIR}    ${NFS_PATH_FOR_ATLASSIAN_SHARED_DIR}    none    bind    0    0" | sudo tee -a /etc/fstab > /dev/null
    echo "${JIRA_SHARED_DIR}         ${NFS_PATH_FOR_JIRA_SHARED_DIR}         none    bind    0    0" | sudo tee -a /etc/fstab > /dev/null
    echo "${CONFLUENCE_SHARED_DIR}   ${NFS_PATH_FOR_CONFLUENCE_SHARED_DIR}   none    bind    0    0" | sudo tee -a /etc/fstab > /dev/null
    echo "${BITBUCKET_SHARED_DIR}    ${NFS_PATH_FOR_BITBUCKET_SHARED_DIR}    none    bind    0    0" | sudo tee -a /etc/fstab > /dev/null
    sudo mount -a


    # 3. configure the file-systems to be exported
    echo """
    ${NFS_v3_ROOT}                          *(rw,sync,no_subtree_check,no_root_squash)
    ${NFS_PATH_FOR_BITBUCKET_SHARED_DIR}    *(rw,sync,no_root_squash,no_subtree_check)
    
    ${NFS_ROOT}                             *(rw,sync,no_subtree_check,crossmnt,fsid=0)
    ${NFS_PATH_FOR_ATLASSIAN_SHARED_DIR}    *(rw,sync,no_root_squash,no_subtree_check)
    ${NFS_PATH_FOR_JIRA_SHARED_DIR}         *(rw,sync,no_root_squash,no_subtree_check)
    ${NFS_PATH_FOR_CONFLUENCE_SHARED_DIR}   *(rw,sync,no_root_squash,no_subtree_check)
    
    """ | sudo tee -a /etc/exports > /dev/null

    # 4. Export the file systems and restart nfs server
    sudo exportfs -ar
    sudo systemctl restart nfs-kernel-server
    5. # Enable and start the rpc-statd  service on the NFS server in order to allow the NFS server to create locks within ${BITBUCKET_HOME}/shared
    sudo systemctl enable rpc-statd 
    sudo systemctl start rpc-statd  
}

print_usage()
{
    cat <<-EOF
    
    Usage:

    setup-nfs-server.sh

    This setup is primarily meant to create a shared home for an Atlassian data-center cluster installation.
    The script will install a NFS server and export the NFS shares for installing atlassian products.
    As of now shared directory is created for Jira, Confluence and Bitbucket.

EOF
}

main() {

    get_args "$@"

    echo_color "Installing NFS Server. "

    install_nfs_server

    # list available exports and their state

    echo_color "Listing available exports:"
    sudo exportfs -v

    echo_color "Finished Installing NFS server"
}

main "$@"
