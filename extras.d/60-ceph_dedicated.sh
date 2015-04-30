# ceph_dedicated.sh - DevStack extras script to install volume types with dedicated pools

if is_service_enabled ceph; then
    if [[ "$1" == "source" ]]; then
        # Initial source
        source $TOP_DIR/lib/ceph_dedicated
    elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
        if is_service_enabled cinder; then
            echo_summary "Configuring Cinder for Ceph (dedicated pools)"
            configure_ceph_dedicated_cinder
        fi
        if is_service_enabled cinder || is_service_enabled nova; then
            echo_summary "Configuring libvirt secret (dedicated pools)"
            import_libvirt_secret_ceph
        fi

        if [ "$REMOTE_CEPH" = "False" ]; then
            if is_service_enabled cinder; then
                echo_summary "Configuring Cinder for Ceph (dedicated pools)"
                configure_ceph_dedicated_embedded_cinder
            fi
        fi
    fi

    if [[ "$1" == "unstack" ]]; then
        if [ "$REMOTE_CEPH" = "True" ]; then
            cleanup_ceph_dedicated_remote
        fi
    fi

    if [[ "$1" == "clean" ]]; then
        if [ "$REMOTE_CEPH" = "True" ]; then
            cleanup_ceph_dedicated_remote
        fi
    fi
fi
