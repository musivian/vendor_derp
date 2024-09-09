# check to see if the supplied product is one we can build
function check_product()
{
    local T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree. Try setting TOP." >&2
        return
    fi
    if (echo -n $1 | grep -q -e "^derp_") ; then
        DERP_BUILD=$(echo -n $1 | sed -e 's/^derp_//g')
    else
        DERP_BUILD=
    fi
    export DERP_BUILD
        TARGET_PRODUCT=$1 \
        TARGET_RELEASE=$2 \
        TARGET_BUILD_VARIANT= \
        TARGET_BUILD_TYPE= \
        TARGET_BUILD_APPS= \
        get_build_var TARGET_DEVICE > /dev/null
    # hide successful answers, but allow the errors to show
}

function repopick()
{
    T=$(gettop)
    $T/vendor/derp/build/tools/repopick.py $@
}

# Repo sync with various flags I'm lazy to type each time
function syncc() {
    time repo sync --force-sync --no-clone-bundle --current-branch --no-tags "$@"
}

function gerrit()
{
    if [ ! -d ".git" ]; then
        echo -e "Please run this inside a git directory";
    else
        git remote rm gerrit 2>/dev/null;
        [[ -z "${GERRIT_USER}" ]] && export GERRIT_USER=$(git config --get review.review.derp.dev.username);
        if [[ -z "${GERRIT_USER}" ]]; then
            git remote add gerrit $(git remote -v | grep -i "github\.com[:\/]DerpFest" | awk '{print $2}' | uniq | sed -e "s|.*github.com[:\/]DerpFest|ssh://review.derpfest.org:29418/DERP|");
        else
            git remote add gerrit $(git remote -v | grep -i "github\.com[:\/]DerpFest" | awk '{print $2}' | uniq | sed -e "s|.*github.com[:\/]DerpFest|ssh://${GERRIT_USER}@review.derpfest.org:29418/DERP|");
        fi
    fi
}

# Make using all available CPUs
function mka() {
    m -j$(nproc --all) "$@"
}

function cout()
{
    if [  "$OUT" ]; then
        cd $OUT
    else
        echo "Couldn't locate out directory.  Try setting OUT."
    fi
}

function fixup_common_out_dir() {
    common_out_dir=$(get_build_var OUT_DIR)/target/common
    target_device=$(get_build_var TARGET_DEVICE)
    common_target_out=common-${target_device}
    if [ ! -z $DERP_FIXUP_COMMON_OUT ]; then
        if [ -d ${common_out_dir} ] && [ ! -L ${common_out_dir} ]; then
            mv ${common_out_dir} ${common_out_dir}-${target_device}
            ln -s ${common_target_out} ${common_out_dir}
        else
            [ -L ${common_out_dir} ] && rm ${common_out_dir}
            mkdir -p ${common_out_dir}-${target_device}
            ln -s ${common_target_out} ${common_out_dir}
        fi
    else
        [ -L ${common_out_dir} ] && rm ${common_out_dir}
        mkdir -p ${common_out_dir}
    fi
}

# Disable ABI checking
export SKIP_ABI_CHECKS=true

# Bypass API modified validations
export DISABLE_STUB_VALIDATION=true

# Override host metadata to make builds more reproducible and avoid leaking info
export BUILD_HOSTNAME=derpbox
export BUILD_USERNAME=private
