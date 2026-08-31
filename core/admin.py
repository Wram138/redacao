from django.contrib import admin
from .models import Pauta, Materia

@admin.register(Pauta)
class PautaAdmin(admin.ModelAdmin):
    list_display = ('retranca', 'data', 'status', 'criada_por') # Limpo
    search_fields = ('retranca', 'direcionamento')
    list_filter = ('status', 'data')

@admin.register(Materia)
class MateriaAdmin(admin.ModelAdmin):
    list_display = ('pauta', 'autor', 'status_edicao', 'status_exibicao', 'data_atualizacao')
    list_filter = ('status_edicao', 'status_exibicao', 'data_atualizacao')
    search_fields = ('pauta__retranca', 'pauta__direcionamento', 'texto')