export PROJECT_ID=dab-media-analyzer
export REJECTED_BUCKET=$PROJECT_ID-flagged

if [ -d "venv" ]; then
    source venv/bin/activate
    python main.py

    # EXIT=$(echo $?)

    # if $EXIT == 0
    #     # clean gsutil mv 
    # elif 
    #     # error while executing program
else
    echo "Error: venv does not exist"
fi