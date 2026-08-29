from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('pautas/', views.lista_pautas, name='lista_pautas'),
    path('materias/', views.lista_materias, name='lista_materias'),
    path('pauta/nova/', views.criar_pauta, name='criar_pauta'),
    path('pauta/<int:pauta_id>/', views.ler_pauta, name='ler_pauta'),
    path('pauta/<int:pauta_id>/escrever/', views.escrever_materia, name='escrever_materia'),
    path('pauta/<int:pauta_id>/ler/', views.ler_materia, name='ler_materia'),
    path('pauta/<int:pauta_id>/editar/', views.editar_pauta, name='editar_pauta'),
]