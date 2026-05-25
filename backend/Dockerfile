FROM node:18-alpine

WORKDIR /app

# Copy package files first (for Docker layer caching)
COPY package.json ./

# Install dependencies
RUN npm install --production

# Copy source code
COPY src/ ./src/

EXPOSE 5000

CMD ["node", "src/server.js"]