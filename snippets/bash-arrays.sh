array=(hi i am "an array of things")

echo "${array[@]}"
echo

for thing in "${array[@]}"; do
  echo "$thing"
done

