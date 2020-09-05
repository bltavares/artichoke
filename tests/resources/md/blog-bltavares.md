+++
title = 'Cluster em casa – Sistema operacional | Bruno Lara Tavares - Blog'
word_count = 1722
+++

Depois de [escolhido o hardware](https://blog.bltavares.com/2019/05/12/cluster_em_casa_hardware/) para montar o cluster em casa, precisamos dar o primeiro passo para ligá-los, ou seja, precisamos de um sistema operacional.

Sistemas operacionais para SBCs
----------

O ideal seria começar com o hardware mais limitado: os Raspberry Pis ARMv6. A grande vantagem de ter escolhido Raspberry Pi ao invés de outros [Single Board Computers](https://en.wikipedia.org/wiki/Single-board_computer) (SBC) está na quantidade de sistemas e suporte oferecido para o hardware.

Precisamos confirmar o suporte a ARMv6 de sistemas operacionais como RancherOS e CoreOS, voltados para criação de clusters, dado que o ARMv6 é uma arquitetura mais antiga e mais lenta, voltado para IoT e hobbistas.

Existem provedores de servidores ARM no mercado, como a [Scaleway](https://www.scaleway.com/en/) e [Packet](https://www.packet.com/), que oferecem computadores ARMv8 64 e isso vem aumentando a demanda de suporte a ARMs, mas ainda é comum não encontrar suporte em sistemas operacionais voltados a contêineres para as versões mais antigas da arquitetura.

### CoreOS ###

[CoreOS](https://coreos.com/) possui alguns componentes que suportam ARM no seu canal alpha/beta de distribuição, mas todos estão bem longes da estabilidade.

O [suporte de plataformas documentado](https://coreos.com/etcd/docs/latest/op-guide/supported-platform.html) aponta que ARM64 é experimental e ARM é instável.

### Rancher OS ###

Rancher OS possui [suporte oficial ao Raspberry Pi](https://rancher.com/docs/os/v1.2/en/running-rancheros/server/raspberry-pi/) desde a versão v0.5.0, mas menciona ter sido testado apenas em Raspberry Pi 3.

Uma das vantagens ofertadas pelo Rancher OS pode ser também um dos nossos problemas. O sistema operacional possui todo os serviços base rodando como contêineres Docker. Como eu precisaria configurar o ClusterHat em um dos PIs, essa característica do OS teria uma grande chance de se tornar um grande problema.

A instalação da placa requer acesso os plugues GPIO, e mesmo sabendo que seria possível repassar o acesso para dentro de um container usando volumes, parece ser uma complexidade desnecessária. Nós já temos complexidade o suficiente no nosso setup, e eu preferiria evitar mais uma delas durante a escolha do OS.

### k3OS ###

A equipe da Rancher Inc. anunciou recentemente o [k3OS](https://k3os.io/), logo depois de anunciar o [k3s](https://k3s.io/). Eu já havia montado o cluster quando o anúncio foi feito, mas vamos analisar ainda assim.

A proposta do k3s é reduzir a complexidade de componentes de um nó rodando kubernetes, e o k3OS oferece um sistema operacional que se configura automaticamente e se associa ao cluster.

A promessa é de rodar um nó de kubernetes usando apenas 512mb de memória, mas alguns dos SBCs do nosso cluster são os pequenos Raspberry Pis Zero W, que possuem apenas os 512mb de memória requeridos.

Isso sozinho já torna improvável escolher o k3s, dado que toda a memória iria para manter o sistema do kubernetes. O segundo motivo para evitar esse sistema no nosso caso é o uso de kubernetes, que [não suporta ARMv6 desde 2017](https://github.com/kubernetes/kubeadm/issues/253#issuecomment-296738890).

A proposta de um sistema que configura sozinho um novo nó para o cluster, e usa poucos recursos, é extremamente interessante para pequenos computadores, mas ainda não para computadores tão pequenos quanto os que escolhi.

Vou acompanhar [o issue pendido suporte a ARM](https://github.com/rancher/k3os/issues/65) para uma possível mudança de OS no futuro.

### BalenaOS ###

Anteriormente chamada [Resin.io](https://www.balena.io/blog/resin-io-changes-name-to-balena-releases-open-source-edition/), o [BalenaOS](https://www.balena.io/os/) oferece uma maneira simples de distribuir e executar software em diversos SBCs.

O sistema operacional se integra com o sistema de build e empacotamento chamado [BalenaCloud](https://www.balena.io/cloud/), que permite que você escreva seu software, associe seu SBC, gere uma imagem Linux já preparada com um sistema de distribuição de pacotes e configurações, tudo configurável por um dashboard.
O serviço é bem completo, oferecendo processo de build do código para a arquitetura do SBC, VPN para garantir a acessibilidade independentemente de onde o computador estiver, sistema de atualização e configuração.

A empresa possui uma engine para containers otimizada para rodar em SBCs chamado [BalenaEngine](https://www.balena.io/engine), otimizada para evitar o uso do disco, dado que na maior parte das vezes estamos rodando o sistema a partir de cartões microSD, que possuem uma taxa de desgaste maior que SSDs e HDDs.

Como o objetivo do projeto é entender quais os componentes necessários para criar o nosso cluster p2p, preferi seguir buscando outros sistemas operacionais. A oferta é bem interessante, principalmente se eu estivesse procurando apenas uma maneira de executar programas que eu mesmo escrevi em vários SBCs.

Apesar de não usar o sistema, recomendo ver a [apresenta sobre as otimizações](https://www.youtube.com/watch?v=cvah8oTNir4) incluídas na engine, que poderia ser utilizada sem todos os outros componentes. Ainda está na minha lista experimentar mudar a engine que roda nos Raspberry Pies e testar quão fácil seria trocar apenas um dos componentes do sistema.

### armbian e raspbian ###

Os dois sistemas são ótimos pontos de partida para construir o que quisermos, com ambos baseados no Debian. O [armbian](https://www.armbian.com/) oferece suporte para várias SBCs, menos o Raspberry Pi, enquanto o [raspbian](https://raspbian.org/) é focado apenas em Raspberry Pis.  
O criador do ClusterHat oferece imagens pré-configuradas para a inicialização da placa e compartilhamento da interface de rede através do conector GPIO e USB, baseadas no [raspbian](https://raspbian.org/).

A grande vantagem de começar com um Debian como base nesse caso é permitir a escolha aberta do nosso orquestrado. A pesquisa do orquestrador fica para o próximo post.
Faltaria apenas configurar Docker para cada um dos computadores usando os scripts de instalação para Debian.

### HypriotOS ###

[HypriotOS](https://github.com/hypriot/image-builder-rpi/releases) é outro sistema operacional focado para SBCs, principalmente para o Raspberry Pi, que tem como objetivo entregar um sistema já pronto para utilizar Docker. Não só apenas o sistema já possui Docker Engine instalado, mas também possui [cloud-init](https://cloud-init.io/) para configuração inicial, similar a servidores na nuvem.

Essa proposta encaixa muito bem com o que estava procurando:

* Instalação fácil, com otimizações para rodar Docker já configuradas
* `cloud-init` permite que eu declare o setup em um arquivo para ser executado durante o primeiro boot, configurando rede e hostname, primeiros pacotes necessários, chaves de acesso e serviços iniciais, sem precisar de conectar um teclado e monitor, ou investigar os IPs de cada placa na rede.
* Baseado em Debian, que permitirá trazer as configurações necessárias para instalar o ClusterHat no sistema sem muito mais esforço que em um sistema onde tudo vive dentro do Docker, e escolher o orquestrador.

Sistemas para os x86
----------

Seguindo com a pesquisa, agora precisamos escolher o sistema operacional para os x86. Para manter uniformidade nos sistemas operacionais, escolhi algo baseado em Debian.

Começando com o processo de boot, me lembrei de diversos posts e links que apareceram na minha linha do tempo, e me pareceu uma boa oportunidade para investigá-los.

* https://twitter.com/jessfraz/status/1019745690887557127
* https://twitter.com/majorhayden/status/934957592228585472
* https://blog.jessfraz.com/post/home-lab-is-the-dopest-lab/
* https://carolynvanslyck.com/blog/2017/10/my-little-cluster/
* https://twitter.com/netbootxyz
* https://blog.sophaskins.net/blog/setting-up-a-home-hypervisor/
* https://github.com/bradfitz/homelab

### PXE Boot – iniciando o sistema pela rede ###

Duas ferramentas me chamaram a atenção: [pixiecore](https://github.com/danderson/netboot/tree/master/pixiecore) e [netboot.xyz](https://netboot.xyz). Ambas permitem que um computador faça bootstrap a partir de uma imagem na rede.[pixiecore](https://github.com/danderson/netboot/tree/master/pixiecore) permite configurar um servidor com uma imagem local, enquanto o [netboot.xyz](https://netboot.xyz) já traz uma lista pré-configurada para carregar um sistema e roda na internet.

Várias das placas mães com UEFI já possuem o a opção para carregar uma imagem pela rede, utilizando [PXE](https://en.wikipedia.org/wiki/Preboot_Execution_Environment), mas cada firmware pode ter problemas na implementação. Para nossa sorte, existe uma imagem mais moderna e com suporte a IPv6 e HTTPS, chamada [iPXE](https://ipxe.org/), que pode evitar os problemas do PXE embutido na placa mãe.

O [netboot.xyz](https://netboot.xyz) nos oferece uma imagem baseada em [iPXE](https://ipxe.org/), já configurada para acessar uma lista de servidores pela internet. O processo de escolha de um novo sistema foi bem fácil e requer apenas gravar um ISO ou pendrive para a inicialização.

Pude escolher entre CoreOS, RancherOS e Debian apenas utilizando um menu durante o boot.

### Mais nós no cluster – Hipervisores e VMs ###

Depois do primeiro sistema x86 pronto, podemos testar a viabilidade de adotar o `pixiecore` para utilizar imagens locais. Podemos usar o [KVM](https://www.linux-kvm.org/page/Main_Page) para virtualizar pequenos servidores e e aumentar a quantidade de nós que temos no nosso cluster.

Alguns colegas já haviam recomendado usar o [UnraidOS](https://www.unraid.net/), e no trabalho eu já havia utilizado vSphere algumas vezes. Esss são escolhas comuns na [comunidade de homelab](https://www.reddit.com/r/homelab/), mas várias outras recomendações me levaram ao [Proxmox VE](https://www.proxmox.com/en/proxmox-ve/features).

[Proxmox VE](https://www.proxmox.com/en/proxmox-ve/features) é construído em cima do Debian, e pode ser instalado por cima de uma instalação básica de Debian. O sistema oferece uma interface web para gerenciar VMs KVM e contêineres LXC. Alem disso, dado que estamos rodando um Debian, também posso utilizar Docker diretamente no hipervisor, apesar de não recomendado.

Optei por instalar do zero, ao invés de migrar de um sistema com Debian já instalado. Depois de configurar o IP fixo e responder algumas perguntas durante a instalação guiada, pude subir uma VM usando a interface web.

Agora podemos testar um boot com [pixiecore](https://github.com/danderson/netboot/tree/master/pixiecore). O processo de subir o servidor de boot requer apenas inicializar um container Docker, compartilhando o namespace de rede para que as VMs recebam pacotes de rede por broadcast. . Os passos estão documentados no README do projeto.
Depois de brigar um pouco com as opções de boot da VM, testando UEFI e BIOS, consegui iniciar VMs tanto com CoreOS quanto RancherOS.

As duas imagens suportam configurações durante o boot, similar ao [cloud-init](https://cloud-init.io/), e é possível prover um arquivo de configuração para ser enviado como user-data junto da imagem do OS.
Infelizmente essa estratégia não funciona bem para criar VMs Debian. As imagens distribuídas oficialmente não têm [cloud-init](https://cloud-init.io/) configuradas, diferente do que acontece nas imagens Debian utilizadas em nuvens.

O HypriotOS nos permite utilizar [cloud-init](https://cloud-init.io/), e seria muito legal poder reaproveitar isso para todos os nós Debian, mas criar uma imagem Debian com tudo configurado para boot pela rede ficou pra depois.

Escolhas
----------

No primeiro momento cheguei a utilizar o sistema pré-configurado com o ClusterHat, para aprender melhor como funciona o processo de boot, inicialização e configuração da placa adicional.

Depois de estudar [o script de geração da imagem](https://github.com/burtyb/clusterhat-image) base, criei um [cloud-init](https://cloud-init.io/) para o HypriotOS. Agora tenho um sistema otimizado para Docker rodando no Raspberry Pi, com o setup inicial descritivo.

No laptop reformado, escolhi utilizar o [Proxmox VE](https://www.proxmox.com/en/proxmox-ve/features) para ganhar acesso a VMs, e configurei Docker mesmo que contraindicado.

Ainda temos uma quantidade em que é viável escolher Debian sem boot pela rede ou [cloud-init](https://cloud-init.io/), e escolhi utilizar o [netboot.xyz](https://netboot.xyz) por enquanto.

Toda a minifrota de computadores roda Debian. As configurações estão [documentadas no GitHub](https://github.com/bltavares/homelab), caso alguém tenha interesse.
Com os computadores ligados e funcionando, o próximo post agora é sobre configuração e conexão.