from django.db import models
from django.contrib.auth.models import User

class Pauta(models.Model):
    STATUS_CHOICES = [
        ('aberta', 'Aberta'),
        ('em_andamento', 'Em Andamento'),
        ('concluida', 'Concluída'),
    ]

    retranca = models.CharField(max_length=50, verbose_name="Retranca", default="SEM_RETRANCA")
    data = models.DateField(verbose_name="Data", null=True, blank=True)
    direcionamento = models.TextField(verbose_name="Direcionamento", default="")
    informacoes = models.TextField(verbose_name="Informações", default="")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='aberta')
    
    # Criador original e logs de edição
    criada_por = models.ForeignKey(User, on_delete=models.CASCADE, related_name='pautas_criadas')
    data_criacao = models.DateTimeField(auto_now_add=True)
    
    # Novos campos para o log e atribuição ao repórter
    reporter_atribuido = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='pautas_atribuidas', verbose_name="Direcionar para Repórter")
    editado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='pautas_editadas', verbose_name="Editado por")
    data_edicao = models.DateTimeField(null=True, blank=True, verbose_name="Data da última edição")

    def __str__(self):
        return self.titulo

class Materia(models.Model):
    STATUS_EDICAO_CHOICES = [
        ('nao_editada', 'Não Editada'),
        ('editada', 'Editada'),
    ]
    STATUS_EXIBICAO_CHOICES = [
        ('gaveta', 'Gaveta'),
        ('exibida', 'Exibida'),
    ]

    # Mantenha os campos que você já tem (como pauta, autor, texto, data_atualizacao...)
    pauta = models.OneToOneField(Pauta, on_delete=models.CASCADE, related_name='materia')
    autor = models.ForeignKey(User, on_delete=models.CASCADE)
    texto = models.TextField(verbose_name="Texto da Matéria")
    data_atualizacao = models.DateTimeField(auto_now=True)
    
    # NOVOS CAMPOS:
    status_edicao = models.CharField(max_length=20, choices=STATUS_EDICAO_CHOICES, default='nao_editada', verbose_name="Edição")
    status_exibicao = models.CharField(max_length=20, choices=STATUS_EXIBICAO_CHOICES, default='gaveta', verbose_name="Exibição")

    def __str__(self):
        return f"Matéria: {self.pauta.retranca}"

# NOVA TABELA: Vincula múltiplos locais e entrevistados a uma única Pauta
class AgendaPauta(models.Model):
    pauta = models.ForeignKey(Pauta, on_delete=models.CASCADE, related_name='agendas')
    local = models.CharField(max_length=200, blank=True, null=True)
    horario = models.TimeField(blank=True, null=True)
    entrevistados = models.TextField(blank=True, null=True)