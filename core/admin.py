from django.contrib import admin
from .models import Pauta, Materia

@admin.register(Pauta)
class PautaAdmin(admin.ModelAdmin):
    list_display = ('retranca', 'data', 'status', 'criada_por') # Limpo
    search_fields = ('retranca', 'direcionamento')
    list_filter = ('status', 'data')

@admin.register(Materia)
class MateriaAdmin(admin.ModelAdmin):
    list_display = ('pauta', 'autor', 'data_atualizacao')
    # Corrigido de 'pauta__titulo' para 'pauta__direcionamento' ou 'pauta__retranca'
    search_fields = ('pauta__retranca', 'pauta__direcionamento', 'texto')