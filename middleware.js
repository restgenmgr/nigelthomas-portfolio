export const config = {
  matcher: ['/accounting-dashboard.html', '/accounting/:path*'],
};

export default function middleware(request) {
  const authHeader = request.headers.get('authorization');

  const expectedUser = process.env.ACCOUNTING_USER;
  const expectedPass = process.env.ACCOUNTING_PASS;

  if (authHeader) {
    const encoded = authHeader.split(' ')[1] || '';

    try {
      const decoded = atob(encoded);
      const sepIndex = decoded.indexOf(':');

      if (sepIndex !== -1) {
        const user = decoded.slice(0, sepIndex);
        const pass = decoded.slice(sepIndex + 1);

        if (user === expectedUser && pass === expectedPass) {
          return;
        }
      }
    } catch {
      // Invalid Authorization header.
    }
  }

  return new Response('Authentication required', {
    status: 401,
    headers: {
      'WWW-Authenticate': 'Basic realm="Private Accounting Dashboard"',
      'Cache-Control': 'no-store',
    },
  });
}
