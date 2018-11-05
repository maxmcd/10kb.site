set -e
aws s3 --profile=max cp ./index.html s3://10kb.site/index.html
aws s3 --profile=max cp ./not-found.txt s3://10kb.site/not-found.txt
aws cloudfront --profile=max create-invalidation \
    --distribution-id E1UAZ0RGAXYQFZ \
    --paths /index.html /not-found.txt
