# Dicas importantes

**##  Terraform/OpenTofu**
 - Se vários arquivos _.tf_ declararem o mesmo _provedor_, vai dar erro de _Duplicate provider configuration_. Centralize tudo num arquivo _providers.tf_.<br>
 - Em produção, a boa prática manda você ter um manual do _Terraform (variable set)_ específico para cada _provedor_ em vez de um manual gigante pra companhia inteira.

**##  Pulumi**
 - O _Pulumi_ usa o conceito de _stacks_. Você tem um arquivo _Pulumi.dev.yaml_ e um _Pulumi.prod.yaml_. Não coloque todas as senhas no arquivo padrão, separe por _stack_.<br>
 - No _Pulumi_ você instancia o _provedor_ no código _(ex: new aws.Provider("meuProvider"))_. Se você instanciar o mesmo _provedor_ em vários arquivos _.ts_ sem passar a referência correta para os recursos, eles ficam confusos.

**##  Crossplane**
 - O _Crossplane_ roda dentro do _Kubernetes_, então ele usa os _secrets_ nativos do _K8s_. Não jogue todos os segredos num único lugar, crie _namespaces_ separados para cada projeto.<br>
 - No _Crossplane_, a "torre de controle" é um recurso chamado _ProviderConfig_. Se você criar mais de um para o _provedor_ e não especificar qual usar nos seus _manifestos YAML_, o sistema entra em conflito.