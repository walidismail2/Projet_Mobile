FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

# Assure la présence du dossier d'uploads dans l'image
RUN mkdir -p public/uploads

EXPOSE 3000

CMD ["npm", "start"]