from django.contrib.auth.decorators import login_required, permission_required
from django.shortcuts import render, get_object_or_404, redirect
from .models import Pauta, Materia
from .forms import MateriaForm

@login_required(login_url='login')
def home(request):
    """Página inicial com os atalhos do sistema"""
    return render(request, 'core/home.html')

def lista_pautas(request):
    pautas = Pauta.objects.all()
    return render(request, 'core/lista_pautas.html', {'pautas': pautas})

@login_required(login_url='login')
@permission_required('core.add_materia', raise_exception=True)
def escrever_materia(request, pauta_id):
    pauta = get_object_or_404(Pauta, id=pauta_id)
    
    # Busca a matéria caso o repórter já tenha começado a escrever
    materia = None
    if request.user.is_authenticated:
        materia = Materia.objects.filter(pauta=pauta, autor=request.user).first()
    
    if request.method == 'POST':
        form = MateriaForm(request.POST, instance=materia)
        if form.is_valid():
            nova_materia = form.save(commit=False)
            nova_materia.pauta = pauta
            nova_materia.autor = request.user # Salva em nome do usuário logado
            nova_materia.save()
            return redirect('lista_pautas')
    else:
        form = MateriaForm(instance=materia)
        
    return render(request, 'core/materia_form.html', {'form': form, 'pauta': pauta})

@login_required(login_url='login')
@permission_required('core.view_materia', raise_exception=True)
def ler_materia(request, pauta_id):
    pauta = get_object_or_404(Pauta, id=pauta_id)
    # Busca a primeira matéria vinculada a esta pauta
    materia = Materia.objects.filter(pauta=pauta).first()
    return render(request, 'core/ler_materia.html', {'pauta': pauta, 'materia': materia})

@login_required(login_url='login')
def lista_materias(request):
    usuario = request.user
    
    # Verifica se o usuário pertence ao grupo 'Repórteres'
    if usuario.groups.filter(name='Repórteres').exists():
        # Repórter vê apenas as próprias matérias
        materias = Materia.objects.filter(autor=usuario).select_related('pauta')
    else:
        # Produtores, Editores e Apresentadores vêem todas
        materias = Materia.objects.all().select_related('pauta')
        
    return render(request, 'core/lista_materias.html', {'materias': materias})

@login_required(login_url='login')
def ler_pauta(request, pauta_id):
    """Exibe os detalhes completos de uma pauta específica."""
    pauta = get_object_or_404(Pauta, id=pauta_id)
    return render(request, 'core/ler_pauta.html', {'pauta': pauta})