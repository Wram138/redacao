from django.db import models
from django.contrib.auth.models import User

class Pauta(models.Model):
    STATUS_CHOICES = [
        ('aberta', 'Aberta'),
        ('em_andamento', 'Em Andamento'),
        ('concluida', 'Concluída'),
    ]

    retranca = models.CharField(max_length=50, verbose_name="Retranca", default="SEM_RETRANCA")
    titulo = models.CharField(max_length=200, verbose_name="Título")
    descricao = models.TextField(verbose_name="Descrição / Diretrizes")
    criada_por = models.ForeignKey(User, on_delete=models.CASCADE, related_name="pautas_criadas", verbose_name="Criada por")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='aberta', verbose_name="Status")
    data_criacao = models.DateTimeField(auto_now_add=True, verbose_name="Data de Criação")

    def __str__(self):
        return self.titulo

class Materia(models.Model):
    pauta = models.ForeignKey(Pauta, on_delete=models.CASCADE, related_name="materias", verbose_name="Pauta de Origem")
    texto = models.TextField(verbose_name="Texto da Matéria")
    autor = models.ForeignKey(User, on_delete=models.CASCADE, related_name="materias_escritas", verbose_name="Autor (Repórter)")
    data_atualizacao = models.DateTimeField(auto_now=True, verbose_name="Última Atualização")

    def __str__(self):
        return f"{self.pauta.titulo} - {self.autor.username}"