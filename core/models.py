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
    pauta = models.ForeignKey(Pauta, on_delete=models.CASCADE, related_name="materias", verbose_name="Pauta de Origem")
    texto = models.TextField(verbose_name="Texto da Matéria")
    autor = models.ForeignKey(User, on_delete=models.CASCADE, related_name="materias_escritas", verbose_name="Autor (Repórter)")
    data_atualizacao = models.DateTimeField(auto_now=True, verbose_name="Última Atualização")

    def __str__(self):
        return f"{self.pauta.titulo} - {self.autor.username}"

# NOVA TABELA: Vincula múltiplos locais e entrevistados a uma única Pauta
class AgendaPauta(models.Model):
    pauta = models.ForeignKey(Pauta, on_delete=models.CASCADE, related_name='agendas')
    local = models.CharField(max_length=200, blank=True, null=True)
    horario = models.TimeField(blank=True, null=True)
    entrevistados = models.TextField(blank=True, null=True)