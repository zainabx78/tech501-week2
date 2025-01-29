#!/bin/bash

cd /repo/app
export DB_HOST=mongodb://10.0.3.4:27017/posts
pm2 start app.js