import { SNSClient } from "@aws-sdk/client-sns";

export function createSnsClient(region: string): SNSClient {
  return new SNSClient({ region });
}
