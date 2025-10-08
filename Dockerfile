FROM node:20-alpine

WORKDIR /opt/genieacs

# Copy semua source dari repo fork kamu
COPY . .

# Install dependencies
RUN npm install

# Build project (abaikan error kecil build frontend)
RUN npm run build || true

EXPOSE 7547 7557 7567 3000

# Jalankan GenieACS
CMD ["npm", "start"]
