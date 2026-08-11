export const config = {
  matcher: ['/accounting-dashboard.html', '/accounting/:path*'],
};

export default function middleware(request) {
  const authHeader = request.headers.get('authorization');

  const expectedUser = process.env.ACCOUNTING_USER;
  const expectedPass = process.env.ACCOUNTING_PASS;

  if (authHeader) {
    const encoded = authHeader.split(' ')[1] || '';
    const decoded = atob(encoded);
    const sepIndex = decoded.indexOf(':');
    const user = decoded.slice(0, sepIndex);
    const pass = decoded.slice(sepIndex + 1);

    if (user === expectedUser && pass === expectedPass) {
      return; // allow request through
    }
  }

  return new Response('Authentication required', {
    status: 401,
    headers: {
      'WWW-Authenticate': 'Basic realm="Private Accounting Dashboard"',
    },
  });
}
