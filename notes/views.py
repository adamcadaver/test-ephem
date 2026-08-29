from django.core.cache import cache
from django.shortcuts import redirect, render

from .models import Note


def note_list(request):
    if request.method == 'POST':
        text = request.POST.get('text', '').strip()
        if text:
            Note.objects.create(text=text)
            cache.delete('note_count')
        return redirect('note_list')

    # Cache the total note count in Redis for a few seconds so repeated
    # page loads don't have to hit Postgres just to show the count.
    note_count = cache.get('note_count')
    if note_count is None:
        note_count = Note.objects.count()
        cache.set('note_count', note_count, timeout=10)

    page_views = cache.incr('page_views') if cache.get('page_views') is not None else 1
    cache.set('page_views', page_views, timeout=None)

    return render(request, 'notes/note_list.html', {
        'notes': Note.objects.all(),
        'note_count': note_count,
        'page_views': page_views,
    })
