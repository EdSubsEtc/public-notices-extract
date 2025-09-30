cp ./package*.json ./dist/
cp ./src/deploy.dockerfile ./dist/

mkdir -p ./dist/sql/
cp ./src/sql/gemstone-pnp-select.sql ./dist/sql/
