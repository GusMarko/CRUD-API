FROM public.ecr.aws/lambda/python:3.9

ARG APP_PATH=api/lambda_handler.py
COPY ${APP_PATH} ${LAMBDA_TASK_ROOT}

CMD [ "lambda_handler.lambda_handler" ]