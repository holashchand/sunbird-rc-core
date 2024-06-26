FROM surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full as wkhtmltopdf
FROM node:20.11.0-alpine3.18 AS install
RUN apk add openssl curl bash
RUN apk add \
    libstdc++ \
    libx11 \
    libxrender \
    libxext \
    libssl3 \
    ca-certificates \
    fontconfig \
    freetype \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation \
    # more fonts
  && fc-cache -f \
  && rm -rf /tmp/*
# Copy wkhtmltopdf files from docker-wkhtmltopdf image
COPY --from=wkhtmltopdf /bin/wkhtmltopdf /bin/wkhtmltopdf
COPY --from=wkhtmltopdf /bin/wkhtmltoimage /bin/wkhtmltoimage
COPY --from=wkhtmltopdf /bin/libwkhtmltox* /bin/
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn

FROM node:20.11.0-alpine3.18 as build
WORKDIR /app
COPY prisma ./prisma/
COPY --from=install /app/node_modules ./node_modules
RUN apk add openssl curl bash
RUN npx prisma generate
COPY . .
RUN yarn build

FROM node:20.11.0-alpine3.18
RUN apk add openssl curl bash
RUN apk add \
    libstdc++ \
    libx11 \
    libxrender \
    libxext \
    libssl3 \
    ca-certificates \
    fontconfig \
    freetype \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation \
  && fc-cache -f \
  && rm -rf /tmp/*
# Copy wkhtmltopdf files from docker-wkhtmltopdf image
COPY --from=wkhtmltopdf /bin/wkhtmltopdf /bin/wkhtmltopdf
COPY --from=wkhtmltopdf /bin/wkhtmltoimage /bin/wkhtmltoimage
COPY --from=wkhtmltopdf /bin/libwkhtmltox* /bin/
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/package*.json ./
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/node_modules ./node_modules
EXPOSE 3000
CMD [ "npm", "run", "start:migrate:prod" ]