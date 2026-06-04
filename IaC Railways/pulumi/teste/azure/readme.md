# Dicas importantes

**##  Terraform/OpenTofu**
 - Se vários arquivos _.tf_ declararem o mesmo _provedor_, vai dar erro de _Duplicate provider configuration_. Centralize tudo num arquivo _providers.tf_.<br>
 - Em produção, a boa prática manda você ter um manual do _Terraform (variable set)_ específico para cada _provedor_ em vez de um manual gigante pra companhia inteira.

**##  Pulumi**
 - O _Pulumi_ usa o conceito de _stacks_. Você tem um arquivo _Pulumi.dev.yaml_ e um _Pulumi.prod.yaml_. Não coloque todas as senhas no arquivo padrão, separe por _stack_.<br>
 - No _Pulumi_ você instancia o _provedor_ no código _(ex: new aws.Provider("meuProvider"))_. Se você instanciar o mesmo _provedor_ em vários arquivos _.ts_ sem passar a referência correta para os recursos, eles ficam confusos.

 Warning (failed to get regions list) é um bug cosmetic do Pulumi YAML. O que acontece é que o Provider tenta validar se a região digitada existe antes de ler a variável de ambiente GOOGLE_CREDENTIALS. Um milissegundo depois, a variável é lida, a autenticação funciona e os recursos são criados com sucesso. Ele não afeta em nada o deploy.