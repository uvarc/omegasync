#!/bin/bash

export OUTPUTS=/srv/shiny-server/yaml_files/slurm/output/processed

ls -1 $OUTPUTS | while IFS= read -r line; do
    subject=$(grep "subject" $OUTPUTS/$line/message.yaml | awk '{$1=""; print $0}')
    email=$(grep "email" $OUTPUTS/$line/message.yaml | awk '{$1=""; print $0}')
    body=$(grep "body" $OUTPUTS/$line/message.yaml | awk '{$1=""; print $0}')
    
    cat <<EOF # mailx -s "$subject" $email instead of cat
Hello,

$body
If you have any questions or concerns,
please reach out to ....@virginia.edu

Best regards,
OmegaSync Team
EOF

done
