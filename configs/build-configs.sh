# Azure profiles
flavors=(azure amazon)
segment=(s m l xl xxl)
unsupported=('azure/values-s-segment.yaml' 'azure/values-m-segment.yaml')

for f in "${flavors[@]}"
do
    echo "Generate $f configs"
    mkdir -vp ${f}
    for s in "${segment[@]}"
    do
        echo "Generate $s configs for $f"
            yq eval-all '. as $item ireduce ({}; . * $item)' reference/values-selectors.yaml \
                reference/compute/values-${s}-segment.yaml \
                reference/storage/values-${s}-segment.yaml \
                reference/${f}/values.yaml > ${f}/values-${s}-segment.yaml
    done
done
 
for item in "${unsupported[@]}"
do
    if [ -f ${item} ];then
        rm -v ${item}
    fi
done