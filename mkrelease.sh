set -e

SEVEN_ZIP="/c/Program\ Files/7-Zip/7z.exe"
VERSION=$(git describe --abbrev=0 --tags)
if [ -z "$VERSION" ]
then
    echo "Version is not set. Tag the current git commit to set it."
    exit 1
fi

mkdir -p tmp
cp -r Entities Maps Rules Scripts Shaders Modname.as tmp
sed -i "s/BrutalityIsleDev/BrutalityIsle/g" tmp/Modname.as
eval "$SEVEN_ZIP a -tzip BrutalityIsle_$VERSION.zip tmp/*"
rm -rf tmp
