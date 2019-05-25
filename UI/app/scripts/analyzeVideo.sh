analyze_image(){

	batch_zip=$1
	second=$2
	resultsPath=$3

	echo "Start analyzing second $second"

	(curl -X POST -u "apikey:piSe4GRX3lUES0f9ODEN0QLIXrN5YtB5_GavalP76Dnu" \
    		-F "images_file=@$batch_zip" \
    		"https://gateway.watsonplatform.net/visual-recognition/api/v3/classify?version=2018-03-19" \
    		| grep '"class"' | sed 's/"//g' | sed 's/class://' | sed 's/,//' | sed -e 's/^[ \t]*//' >> $resultsPath/$second.tags) > /dev/null 2>&1

	echo "Finished analyzing second $second"
}

analyze_audio(){

	resultsPath=$1
	videoFullPath=$2

	echo "Extracting and analyzing audio"

	ffmpeg -i $videoFullPath -f flac -vn $resultsPath/audio.flac -hide_banner > /dev/null 2>&1

	(curl -X POST -u "apikey:96F-UgjUxlmiqUgiUiEa4-9inkw1V6-_CEH6bP0GvyHY" \
		--header "Content-Type: audio/flac " --data-binary @$resultsPath/audio.flac \
		"https://gateway-lon.watsonplatform.net/speech-to-text/api/v1/recognize" \
		| grep '"transcript"' | sed 's/"//g' | sed 's/transcript://' | sed 's/,//' | sed -e 's/^[ \t]*//' >> $resultsPath/transcripts.txt) > /dev/null 2>&1

	echo "Finished analyzing audio"

}

videoFullPath=$1
scriptPath=`dirname $0`
resultsPath=$scriptPath/results

rm -rf $resultsPath > /dev/null 2>&1
mkdir $resultsPath
mkdir $resultsPath/video_frames
mkdir $resultsPath/batch

echo "Extracting video frames"
ffmpeg -i ${videoFullPath} $resultsPath/video_frames/thumb%05d.png -hide_banner > /dev/null 2>&1

echo "calculate frame-rate and sample-rate"
echo "------------------------------------------------"
frame_per_second=`ffmpeg -i ${videoFullPath} 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p"`
frame_per_second=${frame_per_second%.*}
echo "frame per second => $frame_per_second"
frames_per_second=2
sample_rate=$((frame_per_second/frames_per_second))
echo "Sample rate => $sample_rate"
echo "------------------------------------------------"

counter=0
taken_counter=1
second=1
echo "Analyzing frames"
echo "------------------------------------------------"
for frame in $resultsPath/video_frames/*.png;
do
	if [ $((counter % sample_rate)) -eq 0 ]
	then
		mv $frame $resultsPath/batch/
		if [ $((taken_counter % frames_per_second)) -eq 0 ]
		then
			zip -r ${resultsPath}/batch-${second}.zip ${resultsPath}/batch
			analyze_image ${resultsPath}/batch-${second}.zip $second $resultsPath &
			rm -rf ${resultsPath}/batch/*
			second=$((second + 1))
		fi
		taken_counter=$((taken_counter + 1))
	fi
	counter=$((counter + 1))
done

echo "Extraction video audio"
analyze_audio $resultsPath $videoFullPath &

wait
echo "------------------------------------------------"
echo "All threads done"

echo "Remove zip files"
rm -rf ${resultsPath}/batch-*.zip

echo "unique tags"
for frame in $resultsPath/*.tags;
do
	sort -u $frame > $frame.unique
	rm -rf $frame
	mv $frame.unique $frame 
done

echo "Done"

