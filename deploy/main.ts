import { App, Chart, ChartProps } from 'cdk8s';
import { Construct } from 'constructs';

import { IntOrString, KubeDeployment, KubeIngress, KubeService } from './imports/k8s';

interface LobeIngressProps {
  dnsName: string;
  lobeServiceName: string;
  tlsSecretName: string;
}

export class MyChart extends Chart {
  constructor(scope: Construct, id: string, props: ChartProps = {}) {
    super(scope, id, props);

    const appLabel = 'lobe-chat';

    // Define a Kubernetes Deployment
    new KubeDeployment(this, 'lobe-chat', {
      metadata: {
        name: appLabel,
        namespace: 'tribe',
      },
      spec: {
        replicas: 1,
        selector: { matchLabels: { app: appLabel } },
        template: {
          metadata: { labels: { app: appLabel } },
          spec: {
            containers: [
              {
                image: 'tribehealth/lobe-chat:v0.0.2',
                name: 'lobe-chat',
                ports: [{ containerPort: 3210 }],
              },
            ],
          },
        },
      },
    });

    // Define the service
    new KubeService(this, 'lobe-chat-service', {
      metadata: {
        name: appLabel,
        namespace: 'tribe',
      },
      spec: {
        ports: [{ port: 80, targetPort: IntOrString.fromNumber(80) }],
        selector: { app: appLabel },
        type: 'LoadBalancer',
      },
    });

    const ingressProps: LobeIngressProps = {
      dnsName: 'lobe.tribemedia.io',
      lobeServiceName: 'lobe-chat',
      tlsSecretName: 'tribe-tls',
    };

    new KubeIngress(this, 'lobe-chat-ingress', {
      metadata: {
        annotations: {
          'kubernetes.io/ingress.class': 'traefik',
          'traefik.ingress.kubernetes.io/redirect-entry-point': 'https',
          'traefik.ingress.kubernetes.io/redirect-permanent': 'true',
          'traefik.ingress.kubernetes.io/ssl-redirect': 'true',
        },
        name: 'lobe-chat',
        namespace: 'tribe',
      },
      spec: {
        rules: [
          {
            host: `lobe.${ingressProps.dnsName}`,
            http: {
              paths: [
                {
                  backend: {
                    service: {
                      name: ingressProps.lobeServiceName,
                      port: {
                        number: 3210,
                      },
                    },
                  },
                  path: '/',
                  pathType: 'Prefix',
                },
              ],
            },
          },
        ],
        tls: [
          {
            hosts: [`lobe.${ingressProps.dnsName}`],
            secretName: ingressProps.tlsSecretName,
          },
        ],
      },
    });
  }
}

const app = new App();
new MyChart(app, 'deploy');
app.synth();
