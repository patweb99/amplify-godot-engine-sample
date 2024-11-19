import iam from 'aws-cdk-lib/aws-iam';
import s3 from 'aws-cdk-lib/aws-s3';
import { defineBackend } from '@aws-amplify/backend';
import { storage } from './storage/resource';

/**
 * @see https://docs.amplify.aws/react/build-a-backend/ to add storage, functions, and more
 */
const backend = defineBackend({
    storage: storage
});