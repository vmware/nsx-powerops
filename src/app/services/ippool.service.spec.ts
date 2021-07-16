import { TestBed } from '@angular/core/testing';

import { IppoolService } from './ippool.service';

describe('IppoolService', () => {
  let service: IppoolService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(IppoolService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
