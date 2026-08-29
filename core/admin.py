from django.contrib import admin
from .models import Pauta, Materia

@admin.register(Pauta)
class PautaAdmin(admin.ModelAdmin):
    list_display = ('titulo', 'criada_por', 'status', 'data_criacao')
    list_filter = ('status', 'data_criacao')
    search_fields = ('titulo', 'descricao')

@admin.register(Materia)
class MateriaAdmin(admin.ModelAdmin):
    list_display = ('pauta', 'autor', 'data_atualizacao')
    search_fields = ('pauta__titulo', 'texto')