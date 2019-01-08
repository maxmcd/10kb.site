set -e
aws s3 --profile=max cp --recursive ./10kb.site/ s3://10kb.site/
aws cloudfront --profile=max create-invalidation \
    --distribution-id E1UAZ0RGAXYQFZ \
    --paths $(cd 10kb.site; ls | awk '$NF="/"$NF')
