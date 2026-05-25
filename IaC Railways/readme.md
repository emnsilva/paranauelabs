# Dicas importantes

##  Terraform/OpenTofu
 - Se vários arquivos .tf declararem o mesmo provedor, vai dar erro de Duplicate provider configuration. Centralize tudo num arquivo providers.tf.<br>
 - Em produção, a boa prática manda você ter um manual do Terraform (variable set) específico para cada provedor em vez de um manual gigante pra companhia inteira.

##  Pulumi
 - O Pulumi usa o conceito de stacks. Você tem um arquivo Pulumi.dev.yaml e um Pulumi.prod.yaml. Não coloque todas as senhas no arquivo padrão, separe por stack.<br>
 - No Pulumi você instancia o provedor no código (ex: new aws.Provider("meuProvider")). Se você instanciar o mesmo provedor em vários arquivos .ts sem passar a referência correta para os recursos, eles ficam confusos.

##  Crossplane
 - O Crossplane roda dentro do Kubernetes, então ele usa os secrets nativos do K8s. Não jogue todos os segredos num único lugar, crie namespaces separados para cada projeto.<br>
 - No Crossplane, a "torre de controle" é um recurso chamado ProviderConfig. Se você criar mais de um para o provedor e não especificar qual usar nos seus manifestos YAML, o sistema entra em conflito.